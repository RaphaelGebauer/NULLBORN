extends SceneTree
var failures: int=0
var passes: int=0
func check(value: bool,label: String) -> void:
	if value:
		passes+=1
		print("PASS ",label)
	else:
		failures+=1
		push_error("FAIL "+label)
func _initialize() -> void:
	call_deferred("run")
func pulse_damage(world: Node2D) -> bool:
	var before: float=world.model.statistics.total_damage
	var weapons: Dictionary=world.model.weapons
	world.model.weapons={}
	for i in range(180):
		world.combat.update(.016)
		world.update_shots(.016)
	world.model.weapons=weapons
	return world.model.statistics.total_damage>before
func exercise(world: Node2D,source: String,d: Resource) -> bool:
	var model: RefCounted=world.model
	var effects: RefCounted=world.combat.modifiers
	world.enemies.clear()
	world.shots.clear()
	world.combat.effects.clear()
	effects.counters.clear()
	effects.deadlines.clear()
	effects.budget=24
	effects.healed=0
	world.combat.elapsed=0
	var enemy: Dictionary=world.spawn_enemy("guardian",Vector2(60,0))
	enemy.hp=200
	enemy.max_hp=1000
	enemy.statuses={"slow":.5,"freeze":1.0,"mark":1.0}
	world.spawn_enemy("guardian",Vector2(80,0))
	world.grid.rebuild(world.enemies)
	var v: Dictionary=model.registry.weapon_values(source,model.weapons[source])
	v.primary_id=enemy.id
	v.bounce_index=1
	var p: Dictionary=effects.parameters(source,v)
	var kind: String=d.values.effect
	if kind in ["cooldown","radius","motion","reach","width","duration","pierce","chain","bounce","pull"]: return p!=v
	if kind in ["primary","slowed_damage","marked_damage","execute_damage","bounce_damage"]: return effects.damage(source,enemy,100,v)>100
	if kind=="periodic":
		effects.tick(.01)
		world.combat.elapsed=4.1
		effects.tick(.01)
		return pulse_damage(world)
	if kind in ["extra_attack","delayed_attack"]:
		for i in range(12): effects.attack(source,world.combat.params(p),enemy)
		return pulse_damage(world)
	if kind=="retaliate":
		effects.contact()
		return pulse_damage(world)
	if kind=="expiry":
		for i in range(3): effects.expiry(source,enemy.pos,v)
		return pulse_damage(world)
	model.hp=50
	for i in range(30): effects.on_hit(source,enemy,20,v,true,1.0)
	match kind:
		"heal_hits": return model.hp>50 and effects.healed<=3
		"mark": return enemy.statuses.has("imprint_mark")
		"burn_chance","sunburn": return enemy.statuses.has("burn")
		"poison": return enemy.statuses.has("poison")
		"charged": return enemy.statuses.has("charged")
		"slow_chance","snare": return enemy.hits.size()>0 or enemy.statuses.slow==1.0
		"slow_duration": return enemy.statuses.slow>1.0 and enemy.statuses.slow<1.4
		"knockback": return enemy.pos.x>60
		"bonus_hit": return enemy.hp<200
		_: return pulse_damage(world)
func run() -> void:
	var Model=load("res://scripts/run_model.gd")
	var model=Model.new()
	var registry: RefCounted=model.registry
	check(registry.errors.is_empty() and registry.catalogs.mutation.size()==45,"45 valid unique mutation definitions")
	var original_values: Dictionary={}
	for id in registry.catalogs.weapon: original_values[id]=registry.get_def(id).values.duplicate(true)
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for weapon in registry.catalogs.weapon:
		var choices: Array=registry.mutation_choices(weapon)
		check(choices.size()==3,"Three choices for "+weapon)
		for d in choices:
			model=Model.new()
			world.model=model
			model.weapons={weapon:3}
			var requests: Array=[]
			model.mutation_requested.connect(func(id): requests.append(id))
			model.upgrade(weapon)
			check(requests==[weapon] and model.weapons[weapon]==4,"Lv4 queues once: "+d.id)
			check(model.select_mutation(weapon,d.id),"Select "+d.id)
			model.upgrade(weapon)
			check(requests.size()==1 and model.weapons.size()==1 and model.passives.is_empty(),"No repeat or slot cost: "+d.id)
			check(exercise(world,weapon,d),"Functional base effect: "+d.id)
			var recipe: Resource=null
			for item in registry.catalogs.evolution.values():
				if item.values.bases==[weapon]: recipe=item
			model.passives={recipe.values.passive:5}
			model.weapons[weapon]=5
			check(model.evolution(false)=="","Ineligible chest still blocked: "+d.id)
			check(model.evolution(true)==recipe.id and not model.weapon_mutations.has(weapon),"Evolve and remove old imprint owner: "+d.id)
			check(model.weapon_mutations[recipe.id][0].id==d.id and model.weapon_mutations[recipe.id][0].strength==1,"Full inherited imprint: "+d.id)
			check(exercise(world,recipe.id,d),"Functional evolved effect: "+d.id)
	check(registry.catalogs.weapon.keys().all(func(id):return registry.get_def(id).values==original_values[id]),"Combat leaves shared weapon definitions immutable")
	for fusion in ["dusk_storm","day_night"]:
		var recipe: Resource=registry.get_def(fusion)
		for mask in range(4):
			model=Model.new()
			model.weapons={recipe.values.bases[0]:5,recipe.values.bases[1]:5}
			model.passives={recipe.values.passive:5}
			model.ensure_mutations()
			for i in range(2):
				if mask & (1<<i): model.select_mutation(recipe.values.bases[i],registry.mutation_choices(recipe.values.bases[i])[0].id)
			check(model.evolution(true)==fusion and model.weapons.size()==1 and model.passives.size()==1,"Fusion priority and slots "+fusion+str(mask))
			var imprints: Array=model.weapon_mutations.get(fusion,[])
			check(imprints.size()==int(bool(mask&1))+int(bool(mask&2)),"No missing/phantom fusion imprint "+fusion+str(mask))
			if mask&2: check(imprints[-1].strength==.5,"Secondary fusion imprint is Echo 50%")
	# Deterministic half-frequency quantized proc, not round(0.5) or per-frame RNG.
	world.model=model
	model.weapon_mutations={"day_night":[{"id":"mutation_twin_moon","strength":.5}]}
	var echo: Dictionary=model.weapon_mutations["day_night"][0]
	world.combat.modifiers.counters.clear()
	var triggered: int=0
	for i in range(12):
		if world.combat.modifiers.every("day_night",echo,"attack",3): triggered+=1
	check(triggered==2,"Echo quantization fires every sixth eligible attack")
	# Multiple targets from one meteor count as one impact, not several attacks.
	world.model=model
	model.weapons={"meteor_rain":4}
	model.weapon_mutations={"meteor_rain":[{"id":"mutation_comet_shards","strength":1.0}]}
	world.enemies.clear()
	var impact_enemy: Dictionary=world.spawn_enemy("guardian",Vector2(60,0))
	impact_enemy.hp=10000
	impact_enemy.max_hp=10000
	world.combat.modifiers.counters.clear()
	world.combat.effects.clear()
	for i in range(20): world.combat.modifiers.on_hit("meteor_rain",impact_enemy,10,{"impact_token":1},false)
	check(world.combat.effects.is_empty(),"One AoE impact cannot count twenty times")
	for token in [2,3,4]: world.combat.modifiers.on_hit("meteor_rain",impact_enemy,10,{"impact_token":token},false)
	check(world.combat.effects.size()==1,"Fourth distinct impact triggers Comet Shards exactly once")
	world.queue_free()
	await process_frame
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.model.weapons={"arcane_needle":3}
	app.events=["LEVELUP","CHEST","RUNE"]
	app.state="LEVELUP"
	app.cards=["arcane_needle","reward_gold","reward_heal"]
	app.choose(0)
	check(app.state=="MUTATION" and paused and app.events==["LEVELUP","CHEST","RUNE"],"Mutation immediately precedes pending modals")
	var cancel:=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	app._unhandled_input(cancel)
	check(app.state=="MUTATION" and paused,"Back cannot escape mandatory mutation")
	app.choose_mutation(0)
	check(app.state=="LEVELUP" and paused and app.events==["CHEST","RUNE"],"Mutation continues existing FIFO without unpausing")
	check(not app.save.discovered("star_piercer","evolution"),"Mutation never reveals secret evolution")
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("Mutation checks: ",passes," PASS / ",failures," FAIL")
	quit(1 if failures else 0)
