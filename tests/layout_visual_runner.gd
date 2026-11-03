extends SceneTree
var app: Node
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func settle() -> void:
	for i in range(4): await process_frame
func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/layout-"+name+".png"))
func grid_fits(grid: GridContainer,columns: int) -> bool:
	if grid.columns!=columns or grid.get_child_count()!=6: return false
	var first: Control=grid.get_child(0)
	for i in range(6):
		var card: Control=grid.get_child(i)
		if absf(card.size.x-first.size.x)>1: return false
		if i<columns and absf(card.position.y-first.position.y)>1: return false
		if card.get_global_rect().position.x<0 or card.get_global_rect().end.x>root.get_visible_rect().size.x+1: return false
		for label in card.find_children("*","Label",true,false):
			if label.get_minimum_size().y>label.size.y+1: return false
		for j in range(i):
			if card.get_rect().intersects(grid.get_child(j).get_rect()): return false
	return true
func joy(button: JoyButton) -> void:
	var event:=InputEventJoypadButton.new()
	event.button_index=button
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await settle()
func key(code: Key) -> void:
	var event:=InputEventKey.new()
	event.keycode=code
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await settle()
func click(control: Control) -> void:
	var pos: Vector2=root.get_final_transform()*control.get_global_rect().get_center()
	var motion:=InputEventMouseMotion.new()
	motion.position=pos
	Input.parse_input_event(motion)
	await process_frame
	var event:=InputEventMouseButton.new()
	event.position=pos
	event.button_index=MOUSE_BUTTON_LEFT
	event.pressed=true
	Input.parse_input_event(event)
	await process_frame
	event=event.duplicate()
	event.pressed=false
	Input.parse_input_event(event)
	await settle()
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://layout-visual-only.json"
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.events=[]
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		for scale_value in [1.0,1.2]:
			app.save.data.settings.ui_scale=scale_value
			app.apply_settings()
			root.size=resolution
			await settle()
			for full in [false,true]:
				app.model.weapons={"arcane_needle":1}
				app.model.passives={}
				app.model.weapon_mutations={}
				app.model.pending_mutations.clear()
				app.model.runes=[] if not full else ["blood_moon","time_anchor","treasure"]
				if full:
					app.model.weapons={"arcane_needle":5,"ash_bow":5,"frost_shard":5,"lightning_call":5,"gravity_mine":5,"reaper_gaze":5}
					app.model.passives={"runner_boots":5,"power_core":5,"momentum_feather":5,"recovery_moss":5,"execution_seal":5,"frost_thorns":5}
					app.model.ensure_mutations()
					for id in app.model.pending_mutations.duplicate(): app.model.select_mutation(id,app.catalog.mutation_choices(id)[0].id)
					app.model.evolution(true)
					app.model.evolution(true)
					app.model.weapons["prism_disc"]=5
					app.model.ensure_mutations()
					for id in app.model.pending_mutations.duplicate(): app.model.select_mutation(id,app.catalog.mutation_choices(id)[0].id)
					for i in range(17):
						if app.model.evolution(true).is_empty(): break
				app.model.recalculate()
				app.events=[]
				var suffix: String="%d-%s-%s" % [resolution.x,str(scale_value),"full" if full else "empty"]
				app.pause_game()
				await settle()
				check(grid_fits(app.equipment_view.weapon_grid,6) and grid_fits(app.equipment_view.passive_grid,6),"Pause equal six-slot rows, no overlap/clipping "+suffix)
				var grid_center: float=app.equipment_view.weapon_grid.get_global_rect().get_center().x
				check(absf(grid_center-app.panel.get_global_rect().get_center().x)<2,"Pause equipment centered "+suffix)
				await capture("pause-"+suffix)
				app.build_details()
				await settle()
				check(grid_fits(app.equipment_view.weapon_grid,3) and grid_fits(app.equipment_view.passive_grid,3),"Build three-column cards retain all text "+suffix)
				var back: Button=app.detail_actions.get_child(0)
				check(app.detail_actions.get_child_count()==1 and back.text=="Back" and root.get_visible_rect().encloses(back.get_global_rect()) and absf(back.get_global_rect().get_center().x-root.get_visible_rect().size.x*.5)<2,"One centered fixed Back action "+suffix)
				await capture("build-"+suffix)
				var down:=InputEventAction.new()
				down.action="ui_down"
				down.pressed=true
				for i in range(80): app._input(down)
				await settle()
				check(app.detail_scroll.scroll_vertical>0 and root.get_visible_rect().encloses(back.get_global_rect()),"Scrolling keeps Back visible "+suffix)
				if full: await capture("bonuses-"+suffix)
				await joy(JOY_BUTTON_B)
				check(app.state=="PAUSED" and paused,"Controller Back returns paused "+suffix)
				app.build_details()
				await settle()
				await joy(JOY_BUTTON_A)
				check(app.state=="PAUSED" and paused,"Controller A on fixed Back returns paused "+suffix)
				app.build_details()
				await settle()
				await key(KEY_ENTER)
				check(app.state=="PAUSED" and paused,"Keyboard Enter on Back returns paused "+suffix)
				app.build_details()
				await settle()
				await key(KEY_ESCAPE)
				check(app.state=="PAUSED" and paused,"Keyboard Esc returns paused "+suffix)
				app.build_details()
				await settle()
				await click(app.detail_actions.get_child(0))
				check(app.state=="PAUSED" and paused,"Mouse Back returns paused "+suffix)
	app.save.data.settings.ui_scale=1
	app.apply_settings()
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	print("Layout visual checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
