extends SceneTree
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	print("PASS " if ok else "FAIL ",text)
	if ok: passes+=1
	else: failures+=1
func fixture(script: Script) -> Array:
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var model=load("res://scripts/run_model.gd").new()
	model.time=1200
	model.instability=80
	model.weapons={"spark_orbit":4}
	model.ensure_mutations()
	model.select_mutation("spark_orbit",model.registry.mutation_choices("spark_orbit")[0].id)
	var world=script.new()
	world.model=model
	viewport.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.get_node("Camera2D").position_smoothing_enabled=false
	var i: int=0
	for id in model.registry.catalogs.enemy:
		var e: Dictionary=world.spawn_enemy(id,Vector2(-440+(i%5)*210,-200+int(i/5)*140))
		e.statuses={"charged":1.0,"imprint_mark":1.0}
		i+=1
	var elite: Dictionary=world.spawn_enemy(model.registry.get_def("wave_20").values.weights.keys()[0],Vector2(-200,230))
	world.elite_director.promote(elite,["armored","blinking"])
	elite.elite_state.warning=.3
	elite.elite_state.blink_target=Vector2(-350,240)
	world.rifts.node={"pos":Vector2(280,200),"expires":1250.0,"pending":false}
	world.drop(Vector2(40,100),15)
	world.drop(Vector2(80,100),1,"chest",true)
	world.projectile(Vector2(170,-120),Vector2(100,30),{"color":.5},"arcane_needle")
	world.hazard(Vector2(400,180),60,1,20)
	world.combat.add_effect({"behavior":"impact","pos":Vector2(200,200),"radius":40.0,"life":.3})
	world.combat.add_effect({"behavior":"beam","pos":Vector2.ZERO,"radius":150.0,"life":1.0})
	return [viewport,world]
func snapshot(w: Node2D) -> PackedByteArray:
	return var_to_bytes([w.model.time,w.model.hp,w.model.weapons,w.model.weapon_mutations,w.model.rng.state,w.model.statistics.total_damage,w.model.statistics.damage_by_source,w.enemies,w.shots,w.pickups,w.hazards,w.texts,w.combat.effects,w.combat.timers,w.combat.elapsed,w.combat.modifiers.counters,w.combat.modifiers.deadlines,w.rifts.node,w.reactions.visuals,w.player.position])
func run() -> void:
	var current: Array=fixture(load("res://scripts/world.gd"))
	var before: PackedByteArray=snapshot(current[1])
	var reference: Array=[]
	var reference_path: String=OS.get_environment("STERNENBRUCH_RENDER_REFERENCE")
	if not reference_path.is_empty(): reference=fixture(load(reference_path))
	for i in range(4):
		current[1].queue_redraw()
		if not reference.is_empty(): reference[1].queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
	check(before==snapshot(current[1]),"Repeated real rendering preserves gameplay, RNG, pools, stats and mutation cadence")
	var image: Image=current[0].get_texture().get_image()
	check(not image.is_empty(),"Renderer produces real viewport output")
	image.save_png(ProjectSettings.globalize_path("res://docs/screenshots/maintenance-renderer.png"))
	if not reference.is_empty():
		check(image.get_data()==reference[0].get_texture().get_image().get_data(),"Extracted renderer is pixel-identical to pre-M4 drawing with identical state")
		check(snapshot(reference[1])==snapshot(current[1]),"Legacy and extracted rendering preserve identical runtime state")
	current[0].queue_free()
	if not reference.is_empty(): reference[0].queue_free()
	await process_frame
	await process_frame
	print("Render checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
