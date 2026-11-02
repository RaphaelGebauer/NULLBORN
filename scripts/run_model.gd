extends RefCounted
signal mutation_requested(weapon: String)
signal xp_changed
signal health_changed
signal level_changed
signal boss_changed
signal inventory_changed
signal kills_changed
signal rune_changed
signal time_changed
signal gold_changed
signal changed
signal modal_requested(kind: String)
signal ended(victory: bool)
var rng := RandomNumberGenerator.new()
var statistics: RefCounted=preload("res://scripts/run_statistics.gd").new()
var weapon_mutations: Dictionary={}
var pending_mutations: Array[String]=[]
var constellation_nodes: Array=[]
var run_delta: float=0
var rift_state: RefCounted=preload("res://scripts/rift_instability.gd").new()
var hp: float = 100
var max_hp: float = 100
var speed: float = 165
var armor: float = 0
var regeneration: float=0
var might: float = 1
var cooldown: float = 1
var area: float = 1
var duration: float = 1
var projectile_speed: float = 1
var amount: int = 0
var growth: float = 1.1
var greed: float = 1
var magnet: float = 95
var luck: float = 1
var crit: float = 0.05
var crit_factor: float = 1.5
var projectile_damage: float = 1
var time: float = 0
var level: int = 1
var xp: float = 0
var kills: int = 0
var gold: int = 0
var finished: bool = false
var banked: bool = false
var weapons: Dictionary = {"arcane_needle":1}
var passives: Dictionary = {}
var runes: Array = []
var banned: Array = []
var rerolls: int = 0
var skips: int = 0
var banishes: int = 0
var hero: String = "lyra"
var stage: String = "mist"
var fast: bool = false
var curse: float = 0
var registry: RefCounted
var meta: Dictionary = {}
var unlocked_weapons: Array=[]
var evolutions: Array=[]
var bosses: int=0
var temporary_luck: float=0
var resonance: float=0
var chain_cooldown: float=0
var blood_healed: int=0
var blood_minute: int=0
var speed_base: float=165
var speed_bonus: float=1
var cooldown_base: float=1
var pickup_speed: float=1
var pacing: Resource=preload("res://resources/pacing.tres")
func opening_factor(kind: String) -> float:
	return lerpf(float(pacing.values[kind]),1.0,clampf(time/pacing.values.ramp_seconds,0,1))
func update_attack_speed() -> void:
	cooldown=maxf(.15,cooldown_base-.01*meta.get("battle_rhythm",0)*minf(10,time/60))
func update_movement_speed() -> void:
	var minutes: float=minf(10,time/60)
	speed=minf(500,speed_base*(speed_bonus+(.03*meta.get("evasive_instinct",0) if hp/max_hp<.5 else 0)+.01*meta.get("long_stride",0)*minutes+.02*passives.get("momentum_feather",0)*minf(5,time/60)))

func _init() -> void:
	rng.seed = 72047
	registry=preload("res://scripts/data/registry.gd").new()
	unlocked_weapons=registry.catalogs.weapon.keys()
func initialize_meta() -> void:
	rerolls=int(meta.get("rerolls",0))
	skips=int(meta.get("skips",0))
	banishes=int(meta.get("banishes",0))
	recalculate()
func required_xp() -> int:
	return roundi(8+9*(level-1)+0.2*pow(level-1,2))
func add_xp(value: float, apply_growth: bool = true) -> void:
	xp += value * (growth if apply_growth else 1.0)
	xp_changed.emit()
	while xp >= required_xp():
		xp -= required_xp()
		level += 1
		level_changed.emit()
		modal_requested.emit("LEVELUP")
	changed.emit()
func heal(value: float) -> void:
	var previous_hp: float=hp
	hp = minf(max_hp,hp+maxf(0,value))
	statistics.total_healing+=maxf(0,hp-previous_hp)
	health_changed.emit()
	changed.emit()
func hurt(value: float) -> void:
	if finished: return
	var previous_hp: float=hp
	hp = maxf(0,hp-maxf(1,round(value-armor)))
	statistics.damage_taken+=maxf(0,previous_hp-hp)
	health_changed.emit()
	changed.emit()
	if hp <= 0: finish(false)
func finish(victory: bool) -> void:
	if finished: return
	finished = true
	ended.emit(victory)
func tick(delta: float) -> void:
	if finished: return
	run_delta=minf(1800-time,maxf(0,delta)*(2 if fast else 1))
	time+=run_delta
	if regeneration>0: heal(regeneration*delta)
	resonance=maxf(0,resonance-delta)
	chain_cooldown=maxf(0,chain_cooldown-delta)
	if int(time/60)!=blood_minute:
		blood_minute=int(time/60)
		blood_healed=0
	update_movement_speed()
	update_attack_speed()
	time_changed.emit()
	if time >= 1800: finish(true)
func legal() -> Array:
	var result: Array = []
	for kind in ["weapon","passive"]:
		var owned: Dictionary = weapons if kind=="weapon" else passives
		var cap: int = 8 if kind=="weapon" else 5
		for id in registry.catalogs[kind]:
			if id in banned: continue
			if kind=="weapon" and not id in unlocked_weapons: continue
			if owned.get(id,0)>=cap: continue
			if not owned.has(id) and owned.size()>=6: continue
			result.append(id)
	return result
func offers() -> Array:
	var pool := legal()
	var result: Array = []
	while not pool.is_empty() and result.size()<3:
		var total: float=0
		for id in pool: total+=registry.get_def(id).weight
		var roll: float=rng.randf()*total
		var chosen: String=pool[-1]
		for id in pool:
			roll-=registry.get_def(id).weight
			if roll<=0:
				chosen=id
				break
		result.append(chosen)
		pool.erase(chosen)
	for id in ["reward_gold","reward_heal","reward_xp"]:
		if result.size()<3: result.append(id)
	return result
func upgrade(id: String) -> void:
	match id:
		"reward_gold": gold+=25
		"reward_heal":
			if hp<max_hp: heal(30)
			else: gold+=25
		"reward_xp": add_xp(required_xp()*0.1,false)
		_:
			if not id in legal(): return
			var owned: Dictionary=weapons if registry.catalogs.weapon.has(id) else passives
			owned[id]=owned.get(id,0)+1
			if owned==weapons: ensure_mutations()
			recalculate()
			inventory_changed.emit()
	changed.emit()
func recalculate() -> void:
	var ratio: float=hp/max_hp
	var h: Dictionary=registry.get_def(hero).values
	var stats: Dictionary={"max_hp":1.0,"speed":1.0,"might":1.0,"cooldown":1.0,"area":1.0,"duration":1.0,"projectile_speed":1.0,"growth":1.0,"greed":1.0,"luck":1.0,"armor":0.0,"magnet":95.0,"crit_factor":1.5}
	for stat in h.bonuses: stats[stat]+=h.bonuses[stat]
	for id in passives:
		if id in ["multiplicity","recovery_moss","execution_seal","frost_thorns","momentum_feather"]: continue
		var v: Dictionary=registry.get_def(id).values
		stats[v.stat]+=v.bonus*passives[id]
	stats.max_hp+=0.05*meta.get("max_hp",0)
	stats.might+=0.03*meta.get("might",0)
	stats.speed+=0.05*meta.get("speed",0)
	stats.projectile_speed+=.06*meta.get("projectile_speed",0)
	pickup_speed=1+.12*meta.get("pickup_speed",0)
	stats.area+=.04*meta.get("area",0)
	stats.duration+=.05*meta.get("duration",0)
	stats.cooldown-=.02*meta.get("cooldown",0)
	regeneration=.15*meta.get("regeneration",0)+.25*passives.get("recovery_moss",0)
	stats.magnet+=10*meta.get("magnet",0)
	stats.growth+=0.04*meta.get("growth",0)
	stats.greed+=0.05*meta.get("greed",0)+(.25 if "treasure" in runes else 0)
	stats.armor+=floori(meta.get("armor",0)/2.0)
	max_hp=h.hp*stats.max_hp
	hp=clampf(ratio*max_hp,0,max_hp)
	speed_base=h.speed*pacing.values.player_speed
	speed_bonus=stats.speed
	update_movement_speed()
	might=stats.might
	cooldown_base=maxf(.15,stats.cooldown)
	update_attack_speed()
	area=minf(3,stats.area)
	duration=stats.duration
	projectile_speed=stats.projectile_speed
	growth=stats.growth
	greed=stats.greed
	magnet=stats.magnet
	armor=stats.armor
	luck=stats.luck+temporary_luck
	crit=minf(.6,.05*luck+.02*meta.get("crit",0))
	crit_factor=stats.crit_factor
	amount=mini(6,floori(passives.get("multiplicity",0)/2.0))
	projectile_damage=1+.05*(passives.get("multiplicity",0)-amount)
func reroll() -> Array:
	if rerolls<=0: return []
	rerolls-=1
	return offers()
func banish(id: String) -> Array:
	if banishes<=0 or id.begins_with("reward_"): return []
	banishes-=1
	if not id in banned: banned.append(id)
	return offers()
func skip() -> bool:
	if skips<=0: return false
	skips-=1
	add_xp(required_xp()*.2,false)
	return true
func title(id: String) -> String:
	if id=="reward_gold": return "+25 Gold"
	if id=="reward_heal": return "+30 HP (otherwise +25 Gold)"
	if id=="reward_xp": return "+10% XP toward the next level"
	return registry.get_def(id).display_name
func describe(id: String) -> String:
	if id.begins_with("reward_"): return "Instant reward"
	var d: Resource=registry.get_def(id)
	if registry.catalogs.weapon.has(id):
		var lv: int=weapons.get(id,0)
		return "Weapon · Lv %d → %d\n%s" % [lv,lv+1,d.description if lv==0 else d.upgrades[lv-1].text]
	return "Passives · Lv %d → %d\n%s" % [passives.get(id,0),passives.get(id,0)+1,d.description]
func evolution(eligible: bool) -> String:
	if not eligible: return ""
	var recipes: Array=registry.catalogs.evolution.values()
	recipes.sort_custom(func(a,b):
		if a.values.bases.size()!=b.values.bases.size(): return a.values.bases.size()>b.values.bases.size()
		return a.id<b.id)
	for recipe in recipes:
		if weapons.has(recipe.id) or passives.get(recipe.values.passive,0)<recipe.values.get("passive_level",5): continue
		var valid: bool=true
		for base in recipe.values.bases:
			if weapons.get(base,0)<recipe.values.get("weapon_level",5): valid=false
		if not valid: continue
		var inherited: Array=[]
		for i in range(recipe.values.bases.size()):
			var base: String=recipe.values.bases[i]
			for imprint in weapon_mutations.get(base,[]):
				var copy: Dictionary=imprint.duplicate(true)
				copy.strength*=1.0 if i==0 else .5
				inherited.append(copy)
			weapon_mutations.erase(base)
			pending_mutations.erase(base)
			weapons.erase(base)
		if not inherited.is_empty(): weapon_mutations[recipe.id]=inherited
		weapons[recipe.id]=1
		evolutions.append(recipe.id)
		inventory_changed.emit()
		return recipe.id
	return ""
func add_rune(id: String) -> void:
	if id in runes or runes.size()>=3: return
	runes.append(id)
	if id=="treasure" and meta.get("rerolls",0)>0: rerolls+=1
	recalculate()
	rune_changed.emit()
func kill() -> void:
	kills+=1
	if "resonance" in runes and kills%20==0: resonance=3
	if "blood_moon" in runes and kills%30==0 and blood_healed<30:
		heal(3)
		blood_healed+=3
	kills_changed.emit()

func ensure_mutations() -> void:
	for id in weapons:
		if registry.catalogs.weapon.has(id) and weapons[id]>=4 and not weapon_mutations.has(id) and not id in pending_mutations:
			pending_mutations.append(id)
			mutation_requested.emit(id)
func select_mutation(weapon: String, id: String) -> bool:
	if not weapon in pending_mutations or not weapons.has(weapon) or weapon_mutations.has(weapon): return false
	var definition: Resource=registry.get_def(id)
	if definition==null or not registry.catalogs.mutation.has(id) or definition.values.weapon!=weapon: return false
	weapon_mutations[weapon]=[{"id":id,"strength":1.0}]
	pending_mutations.erase(weapon)
	inventory_changed.emit()
	return true
func imprint_text(weapon: String) -> String:
	var names: Array[String]=[]
	var evolved: bool=registry.catalogs.evolution.has(weapon)
	var fusion: bool=evolved and registry.catalogs.evolution[weapon].values.bases.size()>1
	for imprint in weapon_mutations.get(weapon,[]):
		names.append(registry.get_def(imprint.id).display_name+(" · Echo 50%" if imprint.strength<1 else " · Primary" if fusion else ""))
	var prefix: String="Fusion · " if fusion else "Evolved · Mutation inherited: " if evolved else "Mutation: "
	return prefix+", ".join(names)
