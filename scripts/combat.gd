extends RefCounted
# Dispatch by behavior, shared numerical definitions stay immutable in resources.
var world: Node2D
var timers: Dictionary={}
var effects: Array=[]
var free_effects: Array=[]
var elapsed: float=0
var hit_serial: int=0
func update(delta: float) -> void:
	elapsed+=delta
	for id in world.model.weapons:
		var v: Dictionary=world.model.registry.weapon_values(id,world.model.weapons[id])
		timers[id]=timers.get(id,0.0)-delta
		if v.behavior=="orbit":
			orbit(id,v,delta)
		elif timers[id]<=0:
			var target: Dictionary=world.nearest(world.player.position)
			if not target.is_empty() or v.behavior in ["aura","radial","beam","fan"]:
				call("attack_"+v.behavior,id,v,target)
				timers[id]=maxf(.12,v.cooldown*world.model.cooldown*(.85 if world.model.resonance>0 else 1))
	for effect in effects.duplicate():
		effect.age+=delta
		if effect.delay>0:
			effect.delay-=delta
			continue
		if effect.behavior=="beam": update_beam(effect,delta)
		elif effect.behavior=="zone": update_zone(effect,delta)
		elif effect.behavior=="blast":
			if not effect.fired:
				effect.fired=true
				area_hit(effect.pos,effect.radius,effect.damage,effect.values,effect.source)
		if effect.age>effect.life:
			effects.erase(effect)
			free_effects.append(effect)
func params(v: Dictionary) -> Dictionary:
	var result: Dictionary=v.duplicate(true)
	result.damage*=world.model.might
	result.radius*=world.model.area
	result.speed*=world.model.projectile_speed
	result.count+=world.model.amount
	result.duration*=world.model.duration
	if "time_anchor" in world.model.runes and v.behavior in ["zone","orbit","beam"]: result.duration*=1.25
	return result
func add_effect(data: Dictionary) -> void:
	if effects.size()>=180: return
	var e: Dictionary={} if free_effects.is_empty() else free_effects.pop_back()
	e.clear()
	e.merge({"age":0.0,"delay":0.0,"life":.3,"behavior":"blast","pos":Vector2.ZERO,"radius":30.0,"damage":0.0,"values":{},"source":"","fired":false,"tick":0.0,"angle":0.0})
	e.merge(data,true)
	effects.append(e)
func area_hit(pos: Vector2, radius: float, damage: float, values: Dictionary, source: String) -> int:
	var count: int=0
	for e in world.grid.query(pos,radius):
		world.hit(e,damage,values,source)
		count+=1
	return count
func attack_needle(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	if "shard_star" in world.model.runes and (id in ["arcane_needle","frost_shard"]): p.count+=1
	var direction: Vector2=world.player.position.direction_to(target.pos)
	for i in range(int(p.count)):
		world.projectile(world.player.position,direction.rotated((i-(p.count-1)*.5)*.13)*p.speed,p,id)
func attack_fan(id: String,v: Dictionary,_target: Dictionary) -> void:
	var p:=params(v)
	for i in range(int(p.count)):
		var angle: float=(float(i)/maxf(1,p.count-1)-.5)*p.spread
		world.projectile(world.player.position,world.player.facing.rotated(angle)*p.speed,p,id)
func attack_radial(id: String,v: Dictionary,_target: Dictionary) -> void:
	var p:=params(v)
	for i in range(int(p.count)):
		world.projectile(world.player.position,Vector2.RIGHT.rotated(TAU*i/p.count)*p.speed,p,id)
	if p.get("echo",0)>0:
		for i in range(int(p.count)):
			world.projectile(world.player.position,Vector2.RIGHT.rotated(TAU*(i+.5)/p.count)*p.speed,p,id,.22)
func attack_aura(id: String,v: Dictionary,_target: Dictionary) -> void:
	var p:=params(v)
	p.radius+=world.model.amount*6
	var count:=area_hit(world.player.position,p.radius,p.damage,p,id)
	if p.has("leech_hits"):
		hit_serial+=count
		if hit_serial>=15:
			hit_serial-=15
			world.model.heal(1)
	add_effect({"behavior":"visual","pos":world.player.position,"radius":p.radius,"source":id,"values":p,"life":.22})
func orbit(id: String,v: Dictionary,delta: float) -> void:
	var p:=params(v)
	var radius: float=p.radius*(1+.12*(p.duration-3)/3)
	for i in range(int(p.count)):
		var pos: Vector2=world.player.position+Vector2.RIGHT.rotated(elapsed*p.rotation+TAU*i/p.count)*radius
		for e in world.grid.query(pos,16*world.model.area):
			var key: String=id
			if e.hits.get(key,-100.0)<=elapsed:
				e.hits[key]=elapsed+maxf(.12,p.cooldown*world.model.cooldown*(.85 if world.model.resonance>0 else 1))
				world.hit(e,p.damage,p,id)
	if v.get("pulse",0)>0 or v.get("diameter",0)>0:
		if timers.get(id,0)<=0:
			if v.get("diameter",0)>0: attack_beam(id,{"behavior":"beam","damage":p.damage,"cooldown":2,"radius":radius*2,"count":2,"duration":.6,"speed":0,"tick":.25}, {})
			else: area_hit(world.player.position,radius+25,p.damage,p,id)
			timers[id]=2
func attack_lightning(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	var targets: Array=world.visible_enemies()
	for i in range(int(p.count)):
		if targets.is_empty(): break
		var e: Dictionary=targets[world.model.rng.randi_range(0,targets.size()-1)]
		add_effect({"pos":e.pos,"radius":p.radius,"damage":p.damage,"delay":.25,"life":.5,"values":p,"source":id})
		var nearby: Array=world.grid.query(e.pos,220)
		var chain: int=0
		for other in nearby:
			if other.id==e.id: continue
			if chain>=p.get("chain",0): break
			add_effect({"pos":other.pos,"radius":25.0,"damage":p.damage*.75,"delay":.28,"life":.55,"values":p,"source":id})
			chain+=1
func attack_boomerang(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	p.boomerang=true
	p.pierce=999
	for i in range(int(p.count)):
		world.projectile(world.player.position,world.player.position.direction_to(target.pos).rotated((i-(p.count-1)*.5)*.4)*p.speed,p,id)
func attack_bomb(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	var pos: Vector2=target.pos+target.velocity*.35
	add_effect({"pos":pos,"radius":p.radius,"damage":p.damage,"delay":.8,"life":1.1,"values":p,"source":id,"launch":world.player.position})
	if p.get("echo",0)>0: add_effect({"pos":pos,"radius":p.radius*.65,"damage":p.damage*.6,"delay":1.15,"life":1.45,"values":p,"source":id})
	for i in range(int(p.get("secondary",0))):
		add_effect({"pos":pos+Vector2.RIGHT.rotated(TAU*i/5)*85,"radius":45.0,"damage":p.damage*.5,"delay":1.0,"life":1.3,"values":p,"source":id})
func attack_meteor(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	for i in range(int(p.count)):
		var pos: Vector2=target.pos+Vector2.RIGHT.rotated(world.model.rng.randf()*TAU)*world.model.rng.randf_range(0,100)
		add_effect({"pos":pos,"radius":p.radius,"damage":p.damage,"delay":.35+i*.08,"life":.65+i*.08,"values":p,"source":id})
func attack_beam(id: String,v: Dictionary,_target: Dictionary) -> void:
	var p:=params(v)
	for i in range(int(p.count)):
		add_effect({"behavior":"beam","pos":world.player.position,"radius":p.radius,"damage":p.damage,"life":p.duration,"angle":elapsed+i*PI,"values":p,"source":id,"counter":-1 if i%2==1 and p.get("counter",0)>0 else 1})
func update_beam(e: Dictionary,delta: float) -> void:
	e.pos=world.player.position
	e.angle+=delta*1.8*e.counter
	e.tick-=delta
	if e.tick>0: return
	e.tick=maxf(.12,e.values.tick)
	var end: Vector2=e.pos+Vector2.RIGHT.rotated(e.angle)*e.radius
	# Broadphase circle, followed by exact closest-point-to-segment test.
	for enemy in world.grid.query((e.pos+end)*.5,e.radius*.5+15):
		if enemy.pos.distance_to(Geometry2D.get_closest_point_to_segment(enemy.pos,e.pos,end))<enemy.radius+10:
			world.hit(enemy,e.damage,e.values,e.source)
func attack_zone(id: String,v: Dictionary,target: Dictionary) -> void:
	if target.is_empty(): return
	var p:=params(v)
	for i in range(int(p.count)):
		add_effect({"behavior":"zone","pos":target.pos+Vector2(i*90,0),"radius":p.radius,"damage":p.damage,"life":p.duration,"values":p,"source":id})
func update_zone(e: Dictionary,delta: float) -> void:
	if e.values.get("pull",0)>0:
		for enemy in world.grid.query(e.pos,e.radius):
			if not enemy.boss: enemy.pos=enemy.pos.move_toward(e.pos,30*delta)
	e.tick-=delta
	if e.tick<=0:
		e.tick=maxf(.12,e.values.tick)
		area_hit(e.pos,e.radius,e.damage,e.values,e.source)
