extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model=load("res://scripts/run_model.gd").new()
	model.time=1200
	var evolved: Dictionary={}
	var imprints: Dictionary={}
	for id in ["star_piercer","solar_orbit","blood_thorns","zenith_beam","night_storm","ghost_well"]:
		var recipe: Resource=model.registry.get_def(id)
		var base: String=recipe.values.bases[0]
		model.weapons={base:5}
		model.passives={recipe.values.passive:5}
		model.ensure_mutations()
		model.select_mutation(base,model.registry.mutation_choices(base)[0].id)
		assert(model.evolution(true)==id)
		evolved[id]=1
		imprints[id]=model.weapon_mutations[id].duplicate(true)
	model.weapons=evolved
	model.weapon_mutations=imprints
	model.passives={"power_core":5,"clockwork":5,"focus_lens":5,"lasting_seal":5,"multiplicity":5,"blood_vial":5}
	model.recalculate()
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	world.damage_texts=false
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.minute=20
	for i in range(380): world.spawn_enemy("guardian",Vector2.RIGHT.rotated(i*2.39996)*(180+i*.9))
	model.instability=90
	for kind in ["astral_guardian","void_queen","storm_core"]:
		var boss: Dictionary=world.spawn_enemy(kind,Vector2(450,0))
		boss.hp=boss.max_hp*.45
	for affixes in [["armored","blinking"],["swift","hexbound"],["volatile","regenerating"]]:
		var kind: String=model.registry.get_def("wave_20").values.weights.keys().filter(func(id):return id!="splitter")[0]
		world.elite_director.promote(world.spawn_enemy(kind,Vector2(320,120)),affixes)
	var start: int=Time.get_ticks_msec()
	var peak_enemies: int=0
	var peak_shots: int=0
	var peak_pickups: int=0
	var frames: int=5400
	for frame in range(frames):
		# Survival fixture only: immunity keeps combat running; production damage is tested separately.
		world.player.invulnerable=1
		world.player.position=Vector2(sin(frame*.003),cos(frame*.003))*250
		while world.enemies.size()<380: world.spawn_enemy("guardian")
		while world.shots.size()<220: world.projectile(world.player.position,Vector2.RIGHT.rotated(model.rng.randf()*TAU)*300,{"damage":1.0,"pierce":4},"load")
		world._physics_process(1.0/30)
		peak_enemies=maxi(peak_enemies,world.enemies.size())
		peak_shots=maxi(peak_shots,world.shots.size())
		peak_pickups=maxi(peak_pickups,world.pickups.size())
		if frame%900==0: print("STRESS ",frame/30," s · Gegner ",world.enemies.size()," · Projektile ",world.shots.size())
		if world.enemies.size()>440 or world.shots.size()>650 or world.pickups.size()>300 or world.hazards.size()>100:
			push_error("FAIL Entitätscap")
			quit(1)
			return
	var seconds: float=(Time.get_ticks_msec()-start)/1000.0
	print("PASS 180 simulierte Sekunden / 5400 Schritte; Laufzeit ",seconds," s; Peaks Gegner/Projektile/Pickups: ",peak_enemies,"/",peak_shots,"/",peak_pickups,"; Kills ",model.kills)
	world.queue_free()
	await process_frame
	await process_frame
	quit()
