extends SceneTree
var failures: int=0
var passes: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	print("PASS " if ok else "FAIL ",text)
	if ok: passes+=1
	else: failures+=1
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/"+name+".png"))
func run() -> void:
	var app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://maintenance-visual-fixture.json"
	root.add_child(app)
	app.save.persistent=false
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		app.menu()
		app.save.data=app.save.defaults()
		app.collection()
		await capture("maintenance-collection-hidden-%d"%resolution.x)
		check(not app.panel.get_child(2).get_child(0).text.contains("Arcane Needle"),"Hidden collection "+str(resolution))
		app.save.mark_seen("arcane_needle")
		app.save.mark_evolved("star_piercer")
		app.collection()
		await capture("maintenance-collection-known-%d"%resolution.x)
		check(app.panel.get_child(2).get_child(0).text.contains("Star Piercer"),"Known collection "+str(resolution))
		app.save.data.total_gold=1000
		app.save.persistent=true
		app.save.path="user://no-maintenance-visual-parent/save.json"
		app.save.buy("might")
		app.shop()
		await capture("maintenance-purchase-error-%d"%resolution.x)
		check(app.save_feedback_label.visible and app.save.data.total_gold==1000,"Purchase error and rollback "+str(resolution))
		app.save.persistent=false
		app.start_run()
		app.choose_rune(0)
		app.world.set_physics_process(false)
		app.world.player.set_physics_process(false)
		app.save.persistent=true
		app.model.upgrade("prism_disc")
		app.pause_game()
		await capture("maintenance-pending-progress-%d"%resolution.x)
		check(app.save_retry_button.visible and paused and root.gui_get_focus_owner()==app.save_retry_button,"Paused error/controller focus "+str(resolution))
		app.save.persistent=false
		app.save_retry_button.pressed.emit()

		check(not app.save.pending_write and paused,"Retry retains pause "+str(resolution))
		app.save.persistent=true
		app.model.upgrade("reward_gold")
		app.model.finish(false)
		await capture("maintenance-result-pending-%d"%resolution.x)
		var visible: bool=app.detail_actions.get_child_count()==3 and not app.model.banked
		for action in app.detail_actions.get_children(): visible=visible and root.get_visible_rect().encloses(action.get_global_rect())
		check(visible,"Unbanked result keeps error/retry/navigation actions visible "+str(resolution))
		app.save.persistent=false
		app.result(false)
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	print("Maintenance graphical checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
