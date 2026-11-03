extends SceneTree
var app: Node
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
func joy(code: JoyButton) -> void:
	var event:=InputEventJoypadButton.new()
	event.button_index=code
	event.pressure=1
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await process_frame
func mouse(pos: Vector2,click: bool=false) -> void:
	var motion:=InputEventMouseMotion.new()
	pos=root.get_final_transform()*pos
	motion.position=pos
	Input.parse_input_event(motion)
	await process_frame
	if click:
		var event:=InputEventMouseButton.new()
		event.position=pos
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=true
		Input.parse_input_event(event)
		await process_frame
		event=event.duplicate()
		event.pressed=false
		Input.parse_input_event(event)
		await process_frame
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/"+name+".png"))
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://ui-fixes-visual.json"
	root.add_child(app)
	app.save.persistent=false
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		app.save.data.starlight=3
		app.save.data.constellation_nodes=["comet_spark"]
		app.star_map()
		await process_frame
		await process_frame
		var map=app.panel.get_child(2)
		await mouse(map.nodes.veil_seed.get_global_rect().get_center())
		check(map.selected=="comet_spark","Real mouse hover preserves selection "+str(resolution))
		await mouse(map.nodes.veil_seed.get_global_rect().get_center(),true)
		check(map.selected=="veil_seed","Real mouse click selects "+str(resolution))
		await mouse(Vector2(5,5))
		check(map.nodes.veil_seed.get_theme_stylebox("normal").border_width_left==3,"Mouse departure keeps selection outline "+str(resolution))
		map.nodes.quiet_pulse.grab_focus()
		await key(KEY_ENTER)
		check(map.selected=="quiet_pulse" and map.detail.text.contains("Requires Veil Seed"),"Keyboard Enter selects locked star with precise reason "+str(resolution))
		await joy(JOY_BUTTON_DPAD_UP)
		check(root.gui_get_focus_owner()==map.nodes.veil_seed and map.selected=="quiet_pulse","Controller D-pad moves focus without selection "+str(resolution))
		await joy(JOY_BUTTON_A)
		check(map.selected=="veil_seed","Controller A confirms focused star "+str(resolution))
		await mouse(map.purchase.get_global_rect().get_center(),true)
		check(map.purchase.disabled and map.selected=="veil_seed" and map.purchase.text=="Owned","Real purchase keeps owned selection "+str(resolution))
		map.nodes.last_star.grab_focus()
		await key(KEY_ENTER)
		await capture("ui-fixes-star-%d"%resolution.x)
		var fits: bool=root.get_visible_rect().encloses(map.purchase.get_global_rect()) and root.get_visible_rect().encloses(map.detail.get_global_rect())
		for node in map.nodes.values(): fits=fits and root.get_visible_rect().encloses(node.get_global_rect())
		check(fits,"All stars, selected locked outline and inspector fit "+str(resolution))
		app.start_run()
		app.choose_rune(0)
		app.events=[]
		app.model.weapons={"arcane_needle":3}
		app.model.passives={"power_core":2}
		app.pause_game()
		await process_frame
		for child in app.panel.get_children():
			if child is Button and child.text=="Settings":
				await mouse(child.get_global_rect().get_center(),true)
				break
		check(paused and app.state=="SETTINGS","Mouse opens paused Settings "+str(resolution))
		var time: float=app.model.time
		await key(KEY_ESCAPE)
		await capture("ui-fixes-pause-%d"%resolution.x)
		check(paused and app.state=="PAUSED" and app.model.time==time and root.gui_get_focus_owner() is Button,"Esc returns to Pause with frozen clock and focus "+str(resolution))
		for child in app.panel.get_children():
			if child is Button and child.text=="Settings": child.grab_focus(); break
		await joy(JOY_BUTTON_A)
		await joy(JOY_BUTTON_B)
		check(paused and app.state=="PAUSED" and app.model.time==time,"Controller A/B visits Settings and returns paused "+str(resolution))
		await joy(JOY_BUTTON_A)
		check(not paused and app.state=="RUNNING","Controller A on Resume explicitly restarts run "+str(resolution))
		app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	print("UI fixes graphical checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
