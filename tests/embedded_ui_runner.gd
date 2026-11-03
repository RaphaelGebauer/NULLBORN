extends SceneTree
var failures: int=0
var app: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	print("PASS " if ok else "FAIL ",text)
	if not ok: failures+=1
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/")+name+".png")
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	check(app.window_settings.embedded(root),"Native embedding detected")
	app.star_map()
	await capture("embedded-star-map")
	var map=app.panel.get_child(2)
	map.nodes.comet_spark.grab_focus()
	var right:=InputEventJoypadButton.new()
	right.button_index=JOY_BUTTON_DPAD_RIGHT
	right.pressed=true
	Input.parse_input_event(right)
	await process_frame
	check(map.selected=="comet_spark" and root.gui_get_focus_owner()==map.nodes.veil_seed,"Controller focus navigates without selecting")
	var accept:=InputEventJoypadButton.new()
	accept.button_index=JOY_BUTTON_A
	accept.pressed=true
	Input.parse_input_event(accept)
	await process_frame
	accept=accept.duplicate()
	accept.pressed=false
	Input.parse_input_event(accept)
	await process_frame
	check(map.selected=="veil_seed","Controller confirmation selects focused star")
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.build_details()
	await capture("embedded-build")
	check(paused and app.state=="BUILD","Embedded build view pauses the real run")
	for i in range(10): app.set_setting("music",float(i)/10)
	for i in range(3): app.set_setting("resolution",i)
	app.set_setting("fullscreen",true)
	check(app.window_settings.requests==0,"Audio and display settings never resize an embedded window")
	app.model.hurt(99999)
	await capture("embedded-result")
	check(app.state=="DEFEAT" and app.detail_actions.get_child_count()==2,"Embedded defeat retains fixed actions")
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	quit(0 if failures==0 else 1)
