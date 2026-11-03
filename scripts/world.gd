extends Node2D
const Hash = preload("res://scripts/spatial_hash.gd")
const Player = preload("res://scripts/player.gd")
const Combat = preload("res://scripts/combat.gd")
var model: RefCounted
var player: CharacterBody2D
var enemies: Array=[]
var shots: Array=[]
var pickups: Array=[]
var enemy_pool: Array=[]
var shot_pool: Array=[]
var pickup_pool: Array=[]
var hazards: Array=[]
var lanterns: Array=[]
var texts: Array=[]
var grid := Hash.new()
var combat := Combat.new()
var elite_director=preload("res://scripts/elite_affixes.gd").new()
var rifts=preload("res://scripts/rift_nodes.gd").new()
var reactions=preload("res://scripts/element_reactions.gd").new()
var bosses=preload("res://scripts/boss_patterns.gd").new()
var budget: float=0
var lantern_timer: float=20
var serial: int=0
var minute: int=-1
var freeze_time: float=0
var gold_collected: int=0
var shake: float=0
var shake_duration: float=.1
var shake_amplitude: float=0
var impact_cooldown: float=0
var damage_texts: bool=true
var reduce_flash: bool=false
var screen_shake: bool=true:
	set(value):
		screen_shake=value
		if not value:
			shake=0
			if is_instance_valid(player) and player.has_node("Camera2D"): player.get_node("Camera2D").offset=Vector2.ZERO
signal sound_requested(kind: String)
func _ready() -> void:
	player=preload("res://scenes/player.tscn").instantiate()
	player.shape_id=["lyra","brann","noctis","eira"].find(model.hero)
	player.tint=[Color("8df5eb"),Color("f5b679"),Color("c7a1f6"),Color("8acffa")][player.shape_id]
	add_child(player)
	elite_director.world=self
	rifts.world=self
	bosses.world=self
	reactions.world=self
	combat.world=self
	combat.modifiers.world=self
func ring_position() -> Vector2:
	# Camera viewport may resize; use actual world-space visible extent and a 100px margin.
	var half: Vector2=get_viewport_rect().size*.5
	var center: Vector2=player.get_node("Camera2D").get_screen_center_position() if player.has_node("Camera2D") else player.position
	var side: int=model.rng.randi_range(0,3)
	var offset:=Vector2(model.rng.randf_range(-half.x,half.x),model.rng.randf_range(-half.y,half.y))
	if side<2: offset.x=(half.x+100)*(1 if side==0 else -1)
	else: offset.y=(half.y+100)*(1 if side==2 else -1)
	return center+offset
func spawn_enemy(id: String="wisp",pos: Vector2=Vector2.INF,child: bool=false) -> Dictionary:
	var boss: bool=model.registry.get_def(id).values.boss
	if not boss and enemies.size()>=430: return {}
	if pos==Vector2.INF: pos=ring_position()
	serial+=1
	var v: Dictionary=model.registry.get_def(id).values
	var m: int=mini(29,int(model.time/60))
	var hp_scale: float=(1+.055*m+.0025*m*m)*(1+.006*maxi(model.level-1,0))*(1+.10*floori(m/5.0))*(1+model.curse)
	var e: Dictionary={} if enemy_pool.is_empty() else enemy_pool.pop_back()
	e.clear()
	e.merge({"id":serial,"kind":id,"pos":pos,"hp":v.hp*hp_scale,"max_hp":v.hp*hp_scale,"speed":v.speed*minf(1.35,1+.012*m)*(1+.35*model.curse),"damage":v.damage*(1+.035*m),"xp":v.xp,"radius":float(v.radius),"velocity":Vector2.ZERO,"boss":boss,"timer":2.0,"phase":0,"charge":Vector2.ZERO,"age":0.0,"hits":{},"statuses":{},"dot":0.0,"child":child,"spawn_minute":m,"flash":0.0,"leech_source":"","death_fire_source":""})
	elite_director.prepare(e)
	bosses.prepare(e)
	reactions.prepare(e)
	enemies.append(e)
	return e
func nearest(pos: Vector2) -> Dictionary:
	var best: Dictionary={}
	var distance: float=INF
	for e in enemies:
		if e.hp<=0: continue
		var d: float=e.pos.distance_squared_to(pos)
		if d<distance or (d==distance and not best.is_empty() and e.id<best.id):
			distance=d
			best=e
	return best
func visible_enemies() -> Array:
	var half: Vector2=get_viewport_rect().size*.5+Vector2(40,40)
	return enemies.filter(func(e): return e.hp>0 and absf(e.pos.x-player.position.x)<half.x and absf(e.pos.y-player.position.y)<half.y)
func projectile(pos: Vector2,velocity: Vector2,values: Dictionary,source: String,delay: float=0,hostile: bool=false) -> void:
	if shots.size()>=650: return
	if hostile: velocity*=model.opening_factor("projectile_speed")
	var s: Dictionary={} if shot_pool.is_empty() else shot_pool.pop_back()
	s.clear()
	s.merge({"pos":pos,"velocity":velocity,"life":4.0,"age":0.0,"delay":delay,"damage":values.get("damage",10.0)* (1 if hostile else model.projectile_damage),"values":values,"source":source,"pierce":values.get("pierce",0),"bounces":values.get("bounces",0),"hits":{},"hostile":hostile})
	shots.append(s)
func drop(pos: Vector2,value: float,kind: String="xp",eligible: bool=false) -> void:
	if kind=="xp":
		var gems: Array=pickups.filter(func(p): return p.kind=="xp")
		if gems.size()>=250:
			var closest: Dictionary=gems[0]
			for p in gems:
				if p.pos.distance_squared_to(pos)<closest.pos.distance_squared_to(pos): closest=p
			closest.value+=value
			return
	if pickups.size()>=300:
		for existing in pickups:
			if existing.kind==kind and existing.eligible==eligible:
				existing.value+=value
				return
		# Make one slot by merging an equivalent pair; never discard XP, gold or a chest.
		var representative: Dictionary={}
		for existing in pickups:
			var key: String=existing.kind+str(existing.eligible)
			if representative.has(key):
				representative[key].value+=existing.value
				pickups.erase(existing)
				pickup_pool.append(existing)
				break
			representative[key]=existing
	var p: Dictionary={} if pickup_pool.is_empty() else pickup_pool.pop_back()
	p.clear()
	p.merge({"pos":pos,"value":value,"kind":kind,"eligible":eligible,"speed":60.0,"collected":false})
	pickups.append(p)
func hit(e: Dictionary,value: float,values: Dictionary={},source: String="",proc: bool=false,incoming_origin: Vector2=Vector2.INF,inherited_target_factor: float=1.0) -> void:
	if e.is_empty() or e.hp<=0: return
	var damage: float=value*target_star_factor(e)/maxf(.001,inherited_target_factor)
	var critical: bool=false
	if not proc:
		damage=combat.modifiers.damage(source,e,damage,values)
		if e.hp/e.max_hp<=.35: damage*=1+.08*model.passives.get("execution_seal",0)
		if model.rng.randf()<model.crit:
			damage*=model.crit_factor
			critical=true
		if e.statuses.has("mark"): damage*=1.15
		elif e.statuses.has("imprint_mark"): damage*=1+e.get("imprint_mark_bonus",.08)
		if e.kind=="shield" and ((player.position if incoming_origin==Vector2.INF else incoming_origin)-e.pos).normalized().dot(e.velocity.normalized())>.4: damage*=.65
	if e.elite and e.affixes.has("armored") and not values.get("reaction",false): damage*=.8
	var final_damage: float=maxf(1,round(damage))
	model.statistics.record_damage(source,final_damage,e.hp,critical,model.statistics.combat_seconds)
	e.hp-=final_damage
	if proc and e.hp<=0: e.no_death_proc=true
	e.flash=0 if reduce_flash else .06
	if damage_texts and texts.size()<70: texts.append({"pos":e.pos,"text":str(roundi(final_damage))+("!" if critical else ""),"life":.6,"critical":critical})
	if critical and impact_cooldown<=0:
		impact_cooldown=.08
		combat.add_effect({"behavior":"impact","pos":e.pos,"radius":8.0,"life":.12})
	var mutation_slow_base: float=2.0 if values.get("slow",0)>0 else 0.0
	for status in ["burn","poison","slow","mark"]:
		if values.get(status,0)>0:
			e.statuses[status]=3.0 if status in ["burn","mark"] else 4.0 if status=="poison" else 2.0
			if status in ["burn","poison"]: e.dot_sources[status]=source
	var applied_elements: Array=[]
	if values.get("slow_chance",0)>model.rng.randf():
		e.statuses.slow=1.5
		applied_elements.append("frost")
		mutation_slow_base=1.5
	if values.get("freeze_chance",0)>model.rng.randf():
		e.statuses.freeze=.4 if e.boss else .5
		applied_elements.append("frost")
	if values.get("death_fire",0)>0:
		e.statuses.death_fire=4.0
		e.death_fire_source=source
	if e.hp<=0: e.leech_source=source if values.has("leech_kills") and not proc else ""
	if not proc:
		if "ice_crown" in model.runes and model.rng.randf()<.08:
			e.statuses.slow=2
			applied_elements.append("frost")
		applied_elements.append_array(combat.modifiers.on_hit(source,e,final_damage,values,e.hp<=0,mutation_slow_base))
		if "fire" in applied_elements and e.statuses.has("burn"): e.dot_sources.burn=source
		if "toxin" in applied_elements and e.statuses.has("poison"): e.dot_sources.poison=source
		reactions.on_hit(e,source,final_damage,values,applied_elements)
	elite_director.hit(e,source,values,applied_elements)
	if not e.boss and e.kind not in ["guardian","shield","elite_hunter"]:
		e.pos+=player.position.direction_to(e.pos)*3
	if not proc:
		if "chain_spark" in model.runes and model.chain_cooldown<=0 and model.rng.randf()<.05:
			model.chain_cooldown=.25
			for other in grid.query(e.pos,180):
				if other.id!=e.id:
					hit(other,8,{},"chain",true)
					break
	for lantern in lanterns:
		if lantern.hp>0 and lantern.pos.distance_to(e.pos)<35: lantern.hp-=value
func hurt_player(value: float,boss_hit: bool=false) -> bool:
	if player.invulnerable>0 or model.finished: return false
	if "shield_sign" in model.runes and model.rng.randf()<.1:
		combat.add_effect({"behavior":"visual","pos":player.position,"radius":35.0,"life":.4})
		player.invulnerable=.2
		return false
	var previous_damage: float=model.statistics.damage_taken
	model.hurt(value)
	combat.modifiers.contact()
	player.invulnerable=.65
	var attacker: Dictionary=nearest(player.position)
	if not attacker.is_empty(): player.position+=attacker.pos.direction_to(player.position)*10
	player.hit_flash=0 if reduce_flash else .07
	if boss_hit and value>=15: request_shake(1.5,.07)
	sound_requested.emit("hurt")
	if model.passives.get("frost_thorns",0)>0:
		combat.area_hit(player.position,100,5*model.passives.frost_thorns,{"slow":1},"frost_thorns")
	if model.weapons.has("blood_thorns"):
		combat.area_hit(player.position,70,20,{"mutation_secondary":true},"blood_thorns")
	return model.statistics.damage_taken>previous_damage
func _physics_process(delta: float) -> void:
	model.tick(delta)
	if model.finished: return
	player.speed=model.speed*(.8 if player.slow_left>0 else 1)
	rifts.update()
	elite_director.director()
	var m: int=mini(29,int(model.time/60))
	if minute!=m:
		minute=m
		var wave: Dictionary=model.registry.get_def("wave_%02d"%m).values
		if not wave.boss.is_empty(): spawn_enemy(wave.boss)
		if wave.rune and model.runes.size()<3: model.modal_requested.emit("RUNE")
	var spawn_rate: float=(1.6+.38*m+.008*m*m)*(1+.09*floori(m/5.0))*(1+model.curse)*model.registry.get_def(model.stage).values.density
	budget=minf(3,budget+delta*spawn_rate*model.opening_factor("spawn_rate")*model.rift_state.MODIFIERS[model.rift_state.band()].spawn)
	var cap: int=mini(420,55+12*m)
	while budget>=1 and enemies.size()<cap:
		budget-=1
		var weights: Dictionary=model.registry.get_def("wave_%02d"%m).values.weights
		var roll: float=model.rng.randf()*100
		for id in weights:
			roll-=weights[id]
			if roll<=0:
				spawn_enemy(id)
				break
	freeze_time=maxf(0,freeze_time-delta)
	grid.rebuild(enemies)
	for e in enemies.duplicate():
		update_enemy(e,delta)
		if model.finished: return
	grid.rebuild(enemies)
	combat.update(delta)
	update_shots(delta)
	if model.finished: return
	for e in enemies.duplicate():
		if e.hp<=0: kill_enemy(e)
		elif not e.boss and e.pos.distance_to(player.position)>1900:
			enemies.erase(e)
			enemy_pool.append(e)
	update_pickups(delta)
	update_hazards(delta)
	reactions.update(delta)
	update_lanterns(delta)
	for text in texts:
		text.life-=delta
		text.pos.y-=30*delta
	texts=texts.filter(func(t):return t.life>0)
	impact_cooldown=maxf(0,impact_cooldown-delta)
	update_feedback(delta)
	queue_redraw()
func update_enemy(e: Dictionary,delta: float) -> void:
	if e.hp<=0: return
	e.age+=delta
	elite_director.update(e,delta)
	e.flash=maxf(0,e.flash-delta)
	for status in e.statuses.keys():
		e.statuses[status]-=delta
		if e.statuses[status]<=0: e.statuses.erase(status)
	e.dot+=delta
	if e.dot>=1:
		e.dot-=1
		if e.statuses.has("burn"): hit_dot(e,"burn",4)
		if e.statuses.has("poison"): hit_dot(e,"poison",3)
	if e.hp<=0: return
	var direction: Vector2=e.pos.direction_to(player.position)
	var factor: float=1
	if e.statuses.has("slow"): factor=.825 if e.boss else .65
	if e.statuses.has("freeze") or (freeze_time>0 and not e.boss): factor=0
	e.timer-=delta*factor/model.opening_factor("attack_interval")
	var distance: float=e.pos.distance_to(player.position)
	var velocity: Vector2=direction*e.speed
	match e.kind:
		"charger":
			if e.timer<=0:
				e.phase=(e.phase+1)%3
				e.timer=[2.3,.7,.6][e.phase]
				if e.phase==1: e.charge=direction
			if e.phase==1: velocity=Vector2.ZERO
			if e.phase==2: velocity=e.charge*280*(1.18 if e.affixes.has("swift") else 1)
		"sniper":
			velocity=direction*e.speed*(1 if distance>330 else -1 if distance<240 else 0)
			if e.timer<=0:
				projectile(e.pos,direction*150,{"damage":e.damage},"enemy",0,true)
				e.timer=3.5
		"zigzag": velocity+=direction.orthogonal()*sin(e.age*5+e.id)*90
		"healer":
			if e.timer<=0:
				var count: int=0
				for other in grid.query(e.pos,150):
					if count>=4: break
					other.hp=minf(other.max_hp,other.hp+4)
					count+=1
				e.timer=1
		"astral_guardian","void_queen","storm_core": velocity=boss_behavior(e,direction,delta)
	# A small local separation, using the same hash rather than a quadratic all-pairs search.
	var separation:=Vector2.ZERO
	var count: int=0
	for other in grid.query(e.pos,e.radius+8):
		if other.id==e.id: continue
		var diff: Vector2=e.pos-other.pos
		if diff.length_squared()>1: separation+=diff.normalized()*25
		count+=1
		if count>=5: break
	# Boss tells/dashes must not be bent or moved by crowd separation.
	if e.boss: separation=Vector2.ZERO
	if e.elite and (e.elite_state.warning>0 or e.elite_state.teleported):
		velocity=Vector2.ZERO
		separation=Vector2.ZERO
	e.velocity=(velocity+separation)*factor*model.opening_factor("enemy_speed")*model.rift_state.MODIFIERS[model.rift_state.band()].speed
	if e.elite: e.velocity=e.velocity.limit_length(320)
	e.pos+=e.velocity*delta
	if e.boss and distance>1500 and e.transition_left<=0 and e.dash_state==0: e.pos=player.position-direction*650
	if e.pos.distance_to(player.position)<e.radius+13 and not (e.boss and e.transition_left>0):
		elite_director.contact(e,hurt_player(e.damage*model.rift_state.MODIFIERS[model.rift_state.band()].contact,e.boss))
func boss_behavior(e: Dictionary,direction: Vector2,delta: float) -> Vector2:
	return bosses.update(e,direction,delta)
func update_shots(delta: float) -> void:
	for s in shots.duplicate():
		if s.delay>0:
			s.delay-=delta
			continue
		s.life-=delta
		s.age+=delta
		var old: Vector2=s.pos
		if s.values.get("boomerang",false):
			if s.age>.65:
				s.velocity=s.velocity.lerp(s.pos.direction_to(player.position)*s.values.speed,minf(1,delta*6))
				if s.pos.distance_to(player.position)<18: s.life=0
			if s.values.get("spiral",0)>0: s.velocity=s.velocity.rotated(delta*1.2)
		if s.hostile and s.values.has("curve"): s.velocity=s.velocity.rotated(s.values.curve*delta)
		s.pos+=s.velocity*delta
		if s.hostile:
			if player.position.distance_to(Geometry2D.get_closest_point_to_segment(player.position,old,s.pos))<18:
				hurt_player(s.damage*(.97 if s.values.get("boss",false) and model.has_star("guarded_orbit") else 1),s.values.get("boss",false))
				s.life=0
		else:
			var middle: Vector2=(old+s.pos)*.5
			for e in grid.query(middle,old.distance_to(s.pos)*.5+12):
				if e.pos.distance_to(Geometry2D.get_closest_point_to_segment(e.pos,old,s.pos))>e.radius+6: continue
				if s.hits.get(e.id,-10.0)>s.age: continue
				s.hits[e.id]=s.age+.4 if s.values.get("boomerang",false) else 100.0
				hit(e,s.damage,s.values,s.source,s.values.get("mutation_secondary",false),old)
				if s.values.get("split",0)>0:
					var child: Dictionary=s.values.duplicate()
					child.split=0
					child.damage=s.values.damage*.4
					child.pierce=0
					for i in range(4): projectile(e.pos,Vector2.RIGHT.rotated(TAU*i/4)*300,child,s.source)
				if s.bounces>0:
					var candidates: Array=grid.query(e.pos,240).filter(func(other):return other.id!=e.id and not s.hits.has(other.id))
					candidates.sort_custom(func(a,b):
						if is_equal_approx(a.pos.distance_squared_to(e.pos),b.pos.distance_squared_to(e.pos)): return a.id<b.id
						return a.pos.distance_squared_to(e.pos)<b.pos.distance_squared_to(e.pos))
					if not candidates.is_empty():
						s.values=s.values.duplicate(true)
						s.values.bounce_index=s.values.get("bounce_index",0)+1
						s.velocity=e.pos.direction_to(candidates[0].pos)*s.values.speed
						s.pos=e.pos
						s.bounces-=1
						break
					else: s.life=0
				s.pierce-=1
				if s.pierce<0:
					s.life=0
					break
			for lantern in lanterns:
				if lantern.hp>0 and lantern.pos.distance_to(s.pos)<20:
					lantern.hp-=s.damage
					s.life=0
		if s.life<=0:
			if not s.hostile and not s.values.get("mutation_secondary",false): combat.modifiers.expiry(s.source,s.pos,s.values)
			shots.erase(s)
			shot_pool.append(s)
func kill_enemy(e: Dictionary) -> void:
	if not e in enemies: return
	enemies.erase(e)
	model.kill()
	drop(e.pos,e.xp)
	if e.elite: elite_director.death(e)
	if e.boss:
		model.rift_state.change(4)
		model.bosses+=1
		model.boss_killed()
		request_shake(2,.1)
		combat.add_effect({"behavior":"impact","pos":e.pos,"radius":75.0,"life":.3})
		model.boss_changed.emit()
		drop(e.pos,1,"chest",e.spawn_minute>=10)
		drop(e.pos+Vector2(24,0),roundi(model.rng.randi_range(20,50)*(1+model.rift_state.modifiers().reward_gold)),"gold")
	elif e.kind=="elite_hunter" and not e.elite:
		if model.rng.randf()<.08: drop(e.pos,1,"chest",false)
		if model.rng.randf()<.2: drop(e.pos,model.rng.randi_range(5,10),"gold")
	elif not e.elite and model.rng.randf()<.03: drop(e.pos,model.rng.randi_range(1,3),"gold")
	if e.kind=="splitter" and not e.child:
		for i in range(2): spawn_enemy("mite",e.pos+Vector2(i*20-10,0),true)
	if e.kind=="bomber": hazard(e.pos,65,.8,12)
	if e.statuses.has("death_fire") and not e.get("no_death_proc",false):
		combat.add_effect({"pos":e.pos,"radius":60.0,"damage":16.0,"life":.35,"values":{"burn":1,"mutation_secondary":true},"source":e.death_fire_source if not e.death_fire_source.is_empty() else "fire_death"})
	if e.leech_source!="":
		zone_kills+=1
		if zone_kills%20==0: model.heal(1)
	enemy_pool.append(e)
var zone_kills: int=0
var loot_table: Resource=preload("res://resources/loot_table.tres")
func update_pickups(delta: float) -> void:
	for p in pickups.duplicate():
		var distance: float=p.pos.distance_to(player.position)
		if p.kind!="chest" and distance<model.magnet:
			p.speed=minf(800*model.pickup_speed,p.speed+delta*1200*model.pickup_speed)
			p.pos=p.pos.move_toward(player.position,p.speed*delta)
		if p.pos.distance_to(player.position)<21:
			collect(p)
func collect(p: Dictionary) -> void:
	if p.collected or not p in pickups: return
	p.collected=true
	match p.kind:
		"xp": model.add_xp(p.value)
		"gold":
			var value: int=maxi(1,roundi(p.value*model.greed))
			model.gold+=value
			gold_collected+=value
			model.statistics.gold_from_pickups+=value
			model.gold_changed.emit()
		"heal": model.heal(30*p.value)
		"small_heal": model.heal(10*p.value)
		"magnet":
			for gem in pickups.duplicate():
				if gem.kind=="xp": collect(gem)
		"freeze": freeze_time=5
		"nova":
			for e in visible_enemies(): hit(e,25 if e.boss else 100,{},"nova",true)
		"luck":
			model.temporary_luck+=.1
			model.recalculate()
		"chest":
			for i in range(int(p.value)): model.modal_requested.emit("CHEST_EVOLUTION" if p.eligible else "CHEST")
	pickups.erase(p)
	pickup_pool.append(p)
	sound_requested.emit("pickup")
func hazard(pos: Vector2,radius: float,delay: float,damage: float) -> void:
	if hazards.size()<100: hazards.append({"pos":pos,"radius":radius,"delay":delay,"life":delay+.3,"damage":damage,"fired":false})
func update_hazards(delta: float) -> void:
	for h in hazards:
		h.delay-=delta
		h.life-=delta
		if h.life<=0 or h.delay>0 or h.get("preview_only",false): continue
		if h.has("repeat"):
			h.tick-=delta
			if h.tick>0: continue
			h.tick=h.repeat
		elif h.fired: continue
		h.fired=true
		var distance: float=player.position.distance_to(Geometry2D.get_closest_point_to_segment(player.position,h.pos,h.end)) if h.has("end") else player.position.distance_to(h.pos)
		if distance<h.radius+13:
			if h.get("slow",false): player.slow_left=maxf(player.slow_left,1.0)
			hurt_player(h.damage)
	hazards=hazards.filter(func(h): return h.life>0)
func update_lanterns(delta: float) -> void:
	lantern_timer-=delta
	if lantern_timer<=0:
		lantern_timer=model.rng.randf_range(20,35)
		if lanterns.size()<8: lanterns.append({"pos":player.position+Vector2.RIGHT.rotated(model.rng.randf()*TAU)*model.rng.randf_range(160,450),"hp":20.0})
	for lantern in lanterns.duplicate():
		# Aura and projectile interactions are both real attacks on destructibles.
		for id in model.weapons:
			var v: Dictionary=model.registry.weapon_values(id,model.weapons[id])
			if v.behavior in ["aura","orbit"] and lantern.pos.distance_to(player.position)<v.radius*model.area+20: lantern.hp-=delta*v.damage
		if lantern.hp<=0:
			var total: float=0
			for kind in loot_table.values: total+=loot_table.values[kind]*(model.luck if kind in ["magnet","freeze","nova","luck"] else 1)
			var roll: float=model.rng.randf()*total
			var chosen: String="gold"
			for kind in loot_table.values:
				roll-=loot_table.values[kind]*(model.luck if kind in ["magnet","freeze","nova","luck"] else 1)
				if roll<=0:
					chosen=kind
					break
			drop(lantern.pos,model.rng.randi_range(1,3) if chosen=="gold" else 1,chosen)
			lanterns.erase(lantern)
		elif lantern.pos.distance_to(player.position)>2000: lanterns.erase(lantern)
func _draw() -> void:
	if not is_instance_valid(player): return
	var stage: Dictionary=model.registry.get_def(model.stage).values
	var origin:=Vector2i(player.position/96)
	for x in range(origin.x-10,origin.x+11):
		for y in range(origin.y-7,origin.y+8):
			var pos:=Vector2(x,y)*96
			draw_rect(Rect2(pos,Vector2(96,96)),Color(stage.background).lightened(.012 if posmod(x+y,2)==0 else 0))
			var pattern: int=posmod(x*73+y*37,13)
			if pattern<3:
				var c:=Color(stage.accent)
				if model.stage=="ash":
					draw_arc(pos+Vector2(35,40),20,0,TAU,12,c,2)
				else:
					draw_line(pos+Vector2(32,55),pos+Vector2(32,30),c.darkened(.3),4)
					draw_circle(pos+Vector2(32,29),8,c)
			elif pattern==4: draw_rect(Rect2(pos+Vector2(15,30),Vector2(22,9)),Color(stage.accent).darkened(.3))
	if not rifts.node.is_empty():
		var pos: Vector2=rifts.node.pos
		draw_arc(pos,25,0,TAU,6,Color("aab9f6"),3)
		draw_line(pos+Vector2(-10,-15),pos+Vector2(8,15),Color("d2f4ed"),3)
		draw_string(ThemeDB.fallback_font,pos+Vector2(-48,-35),"F / Y · Rift",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d2f4ed"))
	for lantern in lanterns:
		draw_rect(Rect2(lantern.pos-Vector2(8,13),Vector2(16,26)),Color("bd8650"))
		draw_circle(lantern.pos,6,Color("ffee96"))
	for p in pickups:
		var c: Color=Color("4de8d2") if p.kind=="xp" else Color("ffd66b") if p.kind in ["gold","chest"] else Color("ff9fa8")
		var r: float=6 if p.kind=="xp" else 11
		if p.kind=="xp" and p.value>10: r=9;c=Color("a89cff")
		if p.kind=="chest": draw_rect(Rect2(p.pos-Vector2(12,9),Vector2(24,18)),c)
		else: draw_colored_polygon(PackedVector2Array([p.pos+Vector2(0,-r),p.pos+Vector2(r,0),p.pos+Vector2(0,r),p.pos+Vector2(-r,0)]),c)
	for effect in reactions.visuals:
		draw_arc(effect.pos,effect.radius,0,TAU,16,Color("a8d2d9",.35 if reduce_flash else .65),1)
		draw_string(ThemeDB.fallback_font,effect.pos+Vector2(-24,-20),effect.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("bed4db"))
	for e in enemies:
		var c:=Color.from_hsv(model.registry.get_def(e.kind).values.color,.5,.85)
		if e.flash>0 and not reduce_flash: c=c.lerp(Color("c2cdd1"),.35*e.flash/.06)
		if e.statuses.has("slow"): c=Color("87d8ff")
		if e.statuses.has("burn") or e.statuses.has("imprint_glow"): c=c.lerp(Color.ORANGE,.5)
		draw_circle(e.pos+Vector2(0,7),e.radius+2,Color(0,0,0,.4))
		var points:=PackedVector2Array()
		var sides: int=3+int(model.registry.catalogs.enemy.keys().find(e.kind))%5
		for i in range(sides): points.append(e.pos+Vector2.RIGHT.rotated(TAU*i/sides+e.age*.15)*e.radius)
		draw_colored_polygon(points,c)
		draw_circle(e.pos+Vector2(-4,-3),2,Color.WHITE)
		if e.statuses.has("charged"): draw_arc(e.pos,e.radius+4,0,TAU*.75,12,Color("b8c9ff"),1.5)
		if e.statuses.has("imprint_mark"):
			draw_line(e.pos+Vector2(-4,-e.radius-6),e.pos+Vector2(4,-e.radius-6),Color("d6c2f7"),2)
		if e.kind=="shield": draw_arc(e.pos,e.radius+3,e.velocity.angle()-.9,e.velocity.angle()+.9,8,Color("d8e8ed"),4)
		if e.kind=="healer": draw_arc(e.pos,30,0,TAU,16,Color(0.3,1,.5,.4),2)
		if e.kind in ["charger","astral_guardian"] and e.phase==1: draw_line(e.pos,e.pos+e.charge*150,Color("ff696b"),3)
		if e.elite:
			draw_arc(e.pos,e.radius+7,0,TAU,20,Color("e3b475"),2)
			for i in range(e.affixes.size()):
				draw_string(ThemeDB.fallback_font,e.pos+Vector2(-e.radius+i*14,-e.radius-12),e.affixes[i].left(1).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffd996"))
			if e.elite_state.warning>0:
				draw_arc(e.elite_state.blink_target,e.radius+6,0,TAU,12,Color("c3b4f5"),2)
		if e.boss:
			if e.transition_left>0: draw_arc(e.pos,e.radius+12,0,TAU,20,Color("f6c978"),3)
			if e.dash_state==1: draw_line(e.pos,e.pos+e.dash_direction*220,Color("f6c978"),3)
			draw_rect(Rect2(e.pos+Vector2(-45,-e.radius-15),Vector2(90,6)),Color("3d273d"))
			draw_rect(Rect2(e.pos+Vector2(-45,-e.radius-15),Vector2(90*maxf(0,e.hp/e.max_hp),6)),Color("ff777c"))
	for s in shots:
		if s.delay>0: continue
		var c:=Color("ff756d") if s.hostile else Color.from_hsv(s.values.get("color",.5),.5,1)
		if s.bounces>0: draw_arc(s.pos,9,s.age*9,s.age*9+TAU*.8,10,c,3)
		elif s.values.get("boomerang",false): draw_arc(s.pos,14,s.age*8,s.age*8+PI,9,c,4)
		else: draw_line(s.pos-s.velocity.normalized()*14,s.pos,c,4)
	for id in model.weapons:
		var v: Dictionary=model.registry.weapon_values(id,model.weapons[id])
		if v.behavior=="orbit":
			var p: Dictionary=combat.params(combat.modifiers.parameters(id,v,false))
			for i in range(int(p.count)):
				var pos: Vector2=player.position+Vector2.RIGHT.rotated(combat.elapsed*p.rotation+TAU*i/p.count)*p.radius*(1+.12*(p.duration-3)/3)
				draw_circle(pos,11*model.area,Color("ffdf8d"))
	for e in combat.effects:
		var c:=Color.from_hsv(e.values.get("color",.13),.6,1,.3 if reduce_flash else .7)
		if e.behavior=="impact":
			var progress: float=clampf(e.age/e.life,0,1)
			draw_arc(e.pos,e.radius*(.4+progress*.6),0,TAU,16,Color(.8,.8,.65,(.15 if reduce_flash else .5)*(1-progress)),1)
		elif e.behavior=="beam":
			draw_line(player.position,player.position+Vector2.RIGHT.rotated(e.angle)*e.radius,c,e.values.get("hit_width",10.0)*1.2)
		elif e.delay>0:
			draw_arc(e.pos,e.radius,0,TAU,24,Color(c,.55),2)
			if e.has("launch"):
				var t: float=clampf(e.age/.8,0,1)
				var pos: Vector2=e.launch.lerp(e.pos,t)-Vector2(0,sin(t*PI)*90)
				draw_circle(pos,8,c)
		else:
			draw_circle(e.pos,e.radius,Color(c,.03 if reduce_flash else .12))
			draw_arc(e.pos,e.radius,0,TAU,24,c,3)
	for h in hazards:
		var c:=Color(1,.7,.3,.7) if h.delay>0 else Color(1,.3,.3,.6 if reduce_flash else .9)
		if h.has("gap"):
			draw_arc(h.pos,h.radius,h.gap_angle+h.gap*.5,h.gap_angle+TAU-h.gap*.5,30,c,2)
		elif h.has("end"): draw_line(h.pos,h.end,c,3 if h.delay>0 else h.radius*2)
		else: draw_arc(h.pos,h.radius,0,TAU,24,c,2 if h.delay>0 else 8)
	if damage_texts:
		for t in texts: draw_string(ThemeDB.fallback_font,t.pos,t.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17 if t.get("critical",false) else 15,Color(1,.76,.35,t.life/.6) if t.get("critical",false) else Color(.85,.92,.9,t.life/.6))

func hit_dot(e: Dictionary,status: String,damage: float) -> void:
	var source: String=e.dot_sources.get(status,status)
	var reaction: bool=source==reactions.SOURCE
	hit(e,damage*(.5 if reaction and e.boss else 1),{"reaction":reaction,"dot_element":"fire" if status=="burn" else "toxin"},source,true)

func request_shake(amplitude: float,duration: float) -> void:
	if not screen_shake: return
	shake_amplitude=minf(2,maxf(shake_amplitude if shake>0 else 0,amplitude))
	shake_duration=minf(.1,maxf(duration,.001))
	shake=shake_duration
func update_feedback(delta: float) -> void:
	shake=maxf(0,shake-delta)
	var camera: Camera2D=player.get_node("Camera2D")
	# Deterministic, length-bounded and decaying; never consume gameplay RNG for feedback.
	camera.offset=Vector2(sin((1-shake/shake_duration)*PI*2),0)*shake_amplitude*(shake/shake_duration) if screen_shake and shake>0 else Vector2.ZERO

func target_star_factor(enemy: Dictionary) -> float:
	if enemy.elite and model.has_star("hunters_star"): return 1.03
	if enemy.boss and model.instability>=75 and model.has_star("fracture_mastery"): return 1.03
	return 1.0
