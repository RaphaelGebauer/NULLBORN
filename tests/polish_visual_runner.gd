extends SceneTree
var app: Node
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	print("PASS " if ok else "FAIL ",text)
	if not ok: failures+=1
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/")+name+".png")
	print("CAPTURE ",name," ",root.size)
func actions_visible() -> bool:
	for action in app.detail_actions.get_children():
		if not root.get_visible_rect().encloses(action.get_global_rect()): return false
	return true
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.save.data.unlocked_characters=app.catalog.catalogs.character.keys()
	for hero in app.catalog.catalogs.character:
		app.menu()
		app.select_hero(hero)
		app.start_run()
		check(app.model.hero==hero and app.model.weapons.has(app.catalog.get_def(hero).values.weapon),"Real character start "+hero)
	app.menu()
	app.save.data.starlight=63
	for id in preload("res://scripts/data/constellations.gd").NODES: app.save.buy_star(id)
	app.selected_hero="lyra"
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.model.weapons={"arcane_needle":5,"ash_bow":5,"frost_shard":5}
	app.model.passives={"power_core":5,"runner_boots":5,"blood_vial":5}
	app.model.recalculate()
	app.model.ensure_mutations()
	for id in app.model.pending_mutations.duplicate(): app.model.select_mutation(id,app.catalog.mutation_choices(id)[0].id)
	app.events=[]
	app.model.crit=1
	var enemy: Dictionary=app.world.spawn_enemy("guardian",Vector2(120,50))
	enemy.hp=1000
	enemy.max_hp=1000
	app.world.hit(enemy,50,{},"arcane_needle")
	app.model.evolution(true)
	app.model.evolution(true)
	app.world.hit(enemy,80,{},"star_piercer")
	app.world.hit(enemy,40,{},"dusk_storm")
	app.world.grid.rebuild(app.world.enemies)
	app.world.hit(enemy,20,{},"lightning_call")
	app.model.add_xp(12)
	app.model.gold+=100
	app.model.tick(5)
	app.events=[]
	app.world.player.slow_left=.7
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		app.build_details()
		await capture("build-details-%d"%resolution.x)
		check(actions_visible(),"Build fixed actions visible "+str(resolution))
		var down:=InputEventAction.new()
		down.action="ui_down"
		down.pressed=true
		for i in range(80): app._input(down)
		await capture("build-paths-%d"%resolution.x)
		check(app.detail_scroll.scroll_vertical>0 and actions_visible(),"Controller build scrolling keeps actions visible "+str(resolution))
	app.model.time=1800 # Scripted UI fixture; the separate full-run runner simulates every step.
	app.model.finished=true
	app.result(true)
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		app.result(true)
		await capture("run-result-%d"%resolution.x)
		check(actions_visible(),"Result fixed actions visible "+str(resolution))
		app.detail_scroll.scroll_vertical=99999
		await capture("run-damage-%d"%resolution.x)
		check(actions_visible(),"Result actions remain visible after scrolling "+str(resolution))
	app.save.data.settings.ui_scale=1.2
	app.apply_settings()
	root.size=Vector2i(1280,720)
	app.result(true)
	await capture("result-ui-scale")
	check(actions_visible(),"Result fixed actions at UI scale 1.2")
	app.save.data.settings.ui_scale=1
	app.apply_settings()
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	print("Graphical polish checks: ",failures," failures")
	quit(0 if failures==0 else 1)
