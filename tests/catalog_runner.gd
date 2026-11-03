extends SceneTree
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok:
		passes+=1
		print("PASS ",text)
	else:
		failures+=1
		push_error("FAIL "+text)
func run() -> void:
	var model=load("res://scripts/run_model.gd").new()
	model.recalculate()
	model.crit=0
	model.weapons={}
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	world.damage_texts=false
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for id in model.registry.catalogs.weapon.keys()+model.registry.catalogs.evolution.keys():
		world.enemies.clear()
		world.shots.clear()
		world.combat.effects.clear()
		world.combat.timers.clear()
		world.combat.elapsed=0
		var values: Dictionary=model.registry.weapon_values(id,8 if model.registry.catalogs.weapon.has(id) else 1)
		var radii: Array=[30,70,120,180,240]
		if values.behavior=="orbit": radii.append(values.radius*(1+.12*(values.duration-3)/3))
		for radius in radii:
			for i in range(12):
				var e: Dictionary=world.spawn_enemy("guardian",Vector2.RIGHT.rotated(TAU*i/12)*radius)
				e.hp=100000
				e.max_hp=100000
		var before: float=model.statistics.total_damage
		world.grid.rebuild(world.enemies)
		if values.behavior!="orbit": world.combat.call("attack_"+values.behavior,id,values,world.enemies[0])
		for i in range(240):
			world.grid.rebuild(world.enemies)
			if values.behavior=="orbit": world.combat.orbit(id,values,.016)
			world.combat.update(.016)
			world.update_shots(.016)
		check(model.statistics.total_damage>before and model.statistics.damage_by_source.get(id,0)>0,"Actual attack algorithm deals attributed damage: "+id)
	for id in model.registry.catalogs.enemy:
		world.enemies.clear()
		world.shots.clear()
		world.hazards.clear()
		world.combat.effects.clear()
		model.time=1200
		model.hp=100000
		model.max_hp=100000
		model.finished=false
		var e: Dictionary=world.spawn_enemy(id,Vector2(450,0))
		if e.boss: e.hp=e.max_hp*.45
		var start: Vector2=e.pos
		for i in range(120):
			world.player.invulnerable=1
			world.grid.rebuild(world.enemies)
			world.update_enemy(e,1.0/30)
		check(e.pos.is_finite() and e.pos!=start and (not e.boss or e.boss_hp_phase==2 and e.phase_transitions==1),"Live enemy AI and finite movement: "+id)
	for id in model.registry.catalogs.stage:
		world.enemies.clear()
		model.stage=id
		model.time=0
		model.finished=false
		world.minute=-1
		world._physics_process(.1)
		check(world.minute==0 and model.registry.get_def(id).values.density>0,"Arena begins its real wave pipeline: "+id)
	world.queue_free()
	await process_frame
	await process_frame
	print("Catalog checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
