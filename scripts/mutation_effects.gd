extends RefCounted
var world: Node2D
var counters: Dictionary={}
var deadlines: Dictionary={}
var budget: int=24
var healed_minute: int=-1
var healed: int=0
func entries(source: String) -> Array:
	return world.model.weapon_mutations.get(source,[])
func definition(entry: Dictionary) -> Resource:
	return world.model.registry.catalogs.mutation[entry.id]
func key(source: String,entry: Dictionary,suffix: String) -> String:
	return source+":"+entry.id+":"+suffix
func every(source: String,entry: Dictionary,suffix: String,interval: float) -> bool:
	var id:=key(source,entry,suffix)
	counters[id]=counters.get(id,0)+1
	# Quantized echoes fire deterministically at half frequency, never rounded away.
	return int(counters[id])%maxi(1,ceili(interval/entry.strength))==0
func ready(source: String,entry: Dictionary,suffix: String,seconds: float) -> bool:
	var id:=key(source,entry,suffix)
	if deadlines.get(id,-1.0)>world.combat.elapsed: return false
	deadlines[id]=world.combat.elapsed+seconds/entry.strength
	return true
func parameters(source: String,values: Dictionary,advance_quantized: bool=true) -> Dictionary:
	var p: Dictionary=values.duplicate(true)
	for entry in entries(source):
		var d: Dictionary=definition(entry).values
		var amount: float=d.value*entry.strength
		match d.effect:
			"cooldown": p.cooldown*=1+amount
			"radius": p.radius*=1+amount
			"motion":
				p.speed*=1+amount
				p.rotation=p.get("rotation",2.4)*(1+amount)
			"reach":
				if p.speed>0: p.speed*=1+amount
				else: p.radius*=1+amount
			"width":
				if p.behavior=="beam": p["hit_width"]=p.get("hit_width",10.0)*(1+amount)
				else: p.radius*=1+amount
			"duration": p.duration*=1+amount
			"pierce":
				if p.behavior in ["needle","fan","radial","ricochet"] and (entry.strength>=1 or (advance_quantized and every(source,entry,"pierce",1))): p.pierce+=int(d.value)
			"chain":
				if p.behavior=="lightning" and (entry.strength>=1 or (advance_quantized and every(source,entry,"chain",1))): p.chain=mini(4,int(p.get("chain",0))+1)
			"bounce":
				if p.behavior=="ricochet" and (entry.strength>=1 or (advance_quantized and every(source,entry,"bounce",1))): p.bounces=p.get("bounces",0)+int(d.value)
			"pull": p.pull_strength=p.get("pull_strength",1.0)*(1+amount)
	return p
func secondary(source: String,pos: Vector2,radius: float,damage: float,delay: float=0,limit: int=8,excluded: int=-1) -> void:
	if budget<=0: return
	budget-=1
	# Deferred pulses share the existing capped FX pool and carry their source.
	world.combat.add_effect({"behavior":"mutation_pulse","pos":pos,"radius":radius,"damage":damage,"source":source,"delay":delay,"life":delay+.22,"limit":limit,"excluded":excluded})
func fire_pulse(effect: Dictionary) -> void:
	if effect.fired: return
	effect.fired=true
	var count: int=0
	for enemy in world.grid.query(effect.pos,effect.radius):
		if enemy.id==effect.excluded: continue
		world.hit(enemy,effect.damage,{},effect.source,true)
		count+=1
		if count>=effect.limit: break
func attack(source: String,values: Dictionary,target: Dictionary) -> void:
	var pos: Vector2=world.player.position if target.is_empty() else target.pos
	for entry in entries(source):
		var d: Dictionary=definition(entry).values
		match d.effect:
			"extra_attack":
				if every(source,entry,"attack",d.interval):
					if values.behavior=="mine":
						var child: Dictionary=values.duplicate(true)
						child.damage*=d.value
						child.mutation_secondary=true
						world.combat.add_effect({"behavior":"mine","pos":pos+Vector2(35,0),"radius":values.radius,"damage":child.damage,"delay":.4,"life":values.duration,"values":child,"source":source})
					elif values.behavior in ["needle","fan","radial","ricochet","boomerang"]:
						var child: Dictionary=values.duplicate(true)
						child.damage*=d.value
						child.mutation_secondary=true
						child.boomerang=values.behavior=="boomerang"
						child.pierce=0
						child.split=0
						child.echo=0
						child.death_fire=0
						world.projectile(world.player.position,world.player.position.direction_to(pos)*maxf(180,values.speed),child,source)
					else: secondary(source,pos,maxf(45,minf(values.radius,100)),values.damage*d.value)
			"delayed_attack":
				if every(source,entry,"attack",d.interval): secondary(source,pos,minf(140,values.radius),values.damage*d.value,.25)
			"pierce":
				if not values.behavior in ["needle","fan","radial","ricochet"] and every(source,entry,"attack",4): secondary(source,pos,55,values.damage*.25)
			"chain","bounce":
				if not values.behavior in ["lightning","ricochet"] and every(source,entry,"fallback",4): secondary(source,pos,140,values.damage*.25,0,1)
func tick(delta: float) -> void:
	budget=24
	if healed_minute!=int(world.model.time/60):
		healed_minute=int(world.model.time/60)
		healed=0
	for source in world.model.weapons:
		for entry in entries(source):
			var d: Dictionary=definition(entry).values
			if d.effect=="periodic" and ready(source,entry,"periodic",d.interval):
				var v: Dictionary=world.model.registry.weapon_values(source,world.model.weapons[source])
				secondary(source,world.player.position,100,v.damage*world.model.might*d.value)
func damage(source: String,enemy: Dictionary,value: float,values: Dictionary) -> float:
	var result: float=value
	for entry in entries(source):
		var d: Dictionary=definition(entry).values
		var applies: bool=false
		match d.effect:
			"primary": applies=values.get("primary_id",-1)==enemy.id
			"slowed_damage": applies=enemy.statuses.has("slow") or enemy.statuses.has("freeze")
			"marked_damage": applies=enemy.statuses.has("mark") or enemy.statuses.has("imprint_mark")
			"execute_damage": applies=enemy.hp/enemy.max_hp<.35
			"bounce_damage": applies=values.get("bounce_index",0)>0
		if applies: result*=1+d.value*entry.strength
	return result
func new_impact(source: String,entry: Dictionary,suffix: String,values: Dictionary) -> bool:
	if not values.has("impact_token"): return true
	var id:=key(source,entry,suffix)
	if counters.get(id,-1)==values.impact_token: return false
	counters[id]=values.impact_token
	return true
func on_hit(source: String,enemy: Dictionary,damage_value: float,values: Dictionary,killed: bool,slow_base: float=0) -> Array:
	var applied_elements: Array=[]
	for entry in entries(source):
		var d: Dictionary=definition(entry).values
		match d.effect:
			"mark":
				enemy.statuses.imprint_mark=3.0
				enemy.imprint_mark_bonus=maxf(enemy.get("imprint_mark_bonus",0),d.value*entry.strength)
			"burn_chance":
				if world.model.rng.randf()<d.value*entry.strength:
					enemy.statuses.burn=3.0
					applied_elements.append("fire")
			"poison":
				enemy.statuses.poison=d.value*entry.strength
				applied_elements.append("toxin")
			"slow_chance":
				if world.model.rng.randf()<d.value*entry.strength:
					enemy.statuses.slow=1.0
					applied_elements.append("frost")
			"charged":
				enemy.statuses.charged=d.value*entry.strength
				applied_elements.append("storm")
			"slow_duration":
				# Refresh from this hit's normal duration, never compound an existing timer.
				if slow_base>0: enemy.statuses.slow=slow_base*(1+d.value*entry.strength)
			"snare":
				var tag: String="snare:"+source+":"+entry.id
				if enemy.hits.get(tag,-1.0)<=world.combat.elapsed:
					enemy.hits[tag]=world.combat.elapsed+d.interval/entry.strength
					enemy.statuses.slow=1.0
					applied_elements.append("frost")
			"sunburn":
				var tag: String="burn:"+source+":"+entry.id
				if enemy.hits.get(tag,-1.0)<=world.combat.elapsed:
					enemy.hits[tag]=world.combat.elapsed+d.interval/entry.strength
					enemy.statuses.burn=3.0
					applied_elements.append("fire")
			"heal_hits":
				if every(source,entry,"hit",d.interval) and healed<3:
					world.model.heal(1)
					healed+=1
			"chain_hit":
				if every(source,entry,"hit",d.interval): secondary(source,enemy.pos,120,damage_value*d.value,0,1,enemy.id)
			"frozen_blast":
				if enemy.statuses.has("freeze") and ready(source,entry,"frozen",d.interval): secondary(source,enemy.pos,45,damage_value*d.value)
			"bonus_hit":
				if new_impact(source,entry,"last_tick",values) and every(source,entry,"hit",d.interval) and budget>0 and enemy.hp>0:
					budget-=1
					world.hit(enemy,damage_value*d.value,{},source,true)
			"comet_hits":
				if new_impact(source,entry,"last_comet",values) and every(source,entry,"impact",d.interval): secondary(source,enemy.pos,100,damage_value*d.value,0,2,enemy.id)
			"afterglow":
				if (new_impact(source,entry,"last_glow",values) if values.has("impact_token") else ready(source,entry,"afterglow",1)): lingering(source,enemy.pos,55,damage_value*d.value,1,false)
			"knockback":
				if not enemy.boss: enemy.pos=enemy.pos.move_toward(world.player.position,-d.value*entry.strength)
				else: world.combat.add_effect({"behavior":"visual","pos":enemy.pos,"radius":12.0,"life":.1})
			"residual":
				if ready(source,entry,"residual",d.interval): lingering(source,enemy.pos,70,damage_value*d.value,d.interval,true)
			"kill_chain":
				if killed and every(source,entry,"kill",d.interval): secondary(source,enemy.pos,150,damage_value*d.value,0,1,enemy.id)
	return applied_elements
func lingering(source: String,pos: Vector2,radius: float,damage_value: float,duration: float,slow: bool) -> void:
	if budget<=0: return
	budget-=1
	world.combat.add_effect({"behavior":"mutation_zone","source":source,"pos":pos,"radius":radius,"damage":damage_value/4,"life":duration,"interval":duration/4,"remaining_ticks":4,"slow":slow,"tick":0.0})
func zone(effect: Dictionary,delta: float) -> void:
	effect.tick-=delta
	if effect.tick>0 or effect.remaining_ticks<=0: return
	effect.tick+=effect.interval
	effect.remaining_ticks-=1
	for enemy in world.grid.query(effect.pos,effect.radius).slice(0,8):
		if effect.slow: enemy.statuses.slow=.5
		else: enemy.statuses.imprint_glow=.2
		world.hit(enemy,effect.damage,{},effect.source,true)
func expiry(source: String,pos: Vector2,values: Dictionary) -> void:
	for entry in entries(source):
		var d: Dictionary=definition(entry).values
		if d.effect=="expiry" and every(source,entry,"expiry",d.interval): secondary(source,pos,65,values.get("damage",1.0)*d.value)
func contact() -> void:
	for source in world.model.weapons:
		for entry in entries(source):
			var d: Dictionary=definition(entry).values
			if d.effect=="retaliate" and ready(source,entry,"contact",d.interval):
				var v: Dictionary=world.model.registry.weapon_values(source,world.model.weapons[source])
				secondary(source,world.player.position,90,v.damage*world.model.might*d.value)
