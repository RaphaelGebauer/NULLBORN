extends SceneTree
var app: Node
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	var directory: String=OS.get_environment("STERNENBRUCH_CAPTURE_DIR")
	if directory.is_empty(): directory="user://captures"
	DirAccess.make_dir_recursive_absolute(directory)
	image.save_png(directory+"/"+name+".png")
	print("CAPTURE ",name," ",image.get_size())
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	await capture("01-menu")
	app.character_select()
	await capture("02-characters")
	app.select_hero("lyra")
	await capture("03-stages")
	app.start_run()
	await capture("04-rune")
	app.choose_rune(0)
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_D
	key.pressed=true
	Input.parse_input_event(key)
	var start: Vector2=app.world.player.position
	for i in range(40): await physics_frame
	# physics_frame is emitted before node physics callbacks; finish the last tick.
	await process_frame
	key.pressed=false
	Input.parse_input_event(key)
	var moved: float=app.world.player.position.distance_to(start)
	print("PASS keyboard movement ",moved)
	if moved<100:
		push_error("FAIL keyboard movement")
		quit(1)
		return
	var stick:=InputEventJoypadMotion.new()
	stick.axis=JOY_AXIS_LEFT_Y
	stick.axis_value=1
	Input.parse_input_event(stick)
	start=app.world.player.position
	for i in range(20): await physics_frame
	await process_frame
	stick.axis_value=0
	Input.parse_input_event(stick)
	moved=app.world.player.position.distance_to(start)
	print("PASS simulated controller stick ",moved)
	if moved<50:
		push_error("FAIL controller movement")
		quit(1)
		return
	for i in range(20): app.world.spawn_enemy("crawler",app.world.player.position+Vector2.RIGHT.rotated(i*.8)*(100+i*15))
	for id in ["spark_orbit","thorn_halo","sun_beam"]: app.model.upgrade(id)
	for i in range(60): await physics_frame
	await capture("05-arena")
	app.model.add_xp(8,false)
	await process_frame
	await capture("06-level")
	app.choose(0)
	app.model.finish(false)
	await capture("07-result")
	app.menu()
	app.shop()
	await capture("08-shop")
	app.settings()
	await capture("09-settings")
	app.collection()
	await capture("10-collection")
	app.save.data.settings.ui_scale=1.2
	app.apply_settings()
	app.menu()
	await capture("11-ui-scale")
	app.save.data.settings.ui_scale=1.0
	app.apply_settings()
	app.menu()
	app.character_overview()
	await capture("12-character-overview")
	app.start_run()
	app.choose_rune(0)
	app.model.weapons={"arcane_needle":5}
	app.model.passives={"power_core":5}
	app.record_inventory()
	var pause:=InputEventAction.new()
	pause.action="ui_cancel"
	pause.pressed=true
	app._unhandled_input(pause)
	await capture("13-unknown-recipes")
	app.resume()
	app.model.evolution(true)
	app._unhandled_input(pause)
	await capture("14-known-recipes")
	app.menu()
	app.return_to_pause=false
	app.settings()
	app.confirm_reset()
	await capture("15-reset-confirmation")
	app.queue_free()
	await create_timer(.25,true).timeout
	await process_frame
	quit()
