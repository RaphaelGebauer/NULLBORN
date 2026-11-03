extends SceneTree
const Save=preload("res://scripts/save_manager.gd")
const Model=preload("res://scripts/run_model.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok:
		passes+=1
		print("PASS ",message)
	else:
		failures+=1
		push_error("FAIL "+message)
func block_write(s: RefCounted) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(s.path+".tmp"))
func unblock(s: RefCounted) -> void:
	DirAccess.remove_absolute(s.path+".tmp")
func run() -> void:
	var s=Save.new()
	s.path="user://maintenance-save.json"
	s.data.total_gold=1000
	s.data.starlight=10
	check(s.save(),"Real baseline save succeeds")
	var original: String=FileAccess.get_file_as_string(s.path)
	var before: Dictionary=s.data.duplicate(true)
	block_write(s)
	check(not s.buy("might") and s.data==before and not s.pending_write,"Failed meta buy rolls back every field")
	check(FileAccess.get_file_as_string(s.path)==original and not s.warning.is_empty(),"Failed write leaves previous durable save intact and reports error")
	check(not s.buy_star("comet_spark") and s.data==before,"Star purchase uses identical rollback semantics")
	check(not s.reset_all() and s.data==before,"Reset failure preserves full existing save")
	var model=Model.new()
	model.time=1200
	model.gold=125
	model.bosses=2
	s.finish_run(model,false)
	check(not model.banked and s.data==before,"Failed finish keeps gold/stars/records unbooked")
	unblock(s)
	check(s.buy("might") and s.data.total_gold==925 and s.data.meta_powerups.might==1,"Retry meta purchase charges exactly once")
	s.finish_run(model,false)
	var banked: Dictionary=s.data.duplicate(true)
	s.finish_run(model,false)
	check(model.banked and s.data==banked and s.data.starlight==13,"Recovered finish banks once with exact star reward")
	check(s.buy_star("comet_spark") and s.data.starlight==12,"Recovered star purchase charges once")
	var reload=Save.new()
	reload.path=s.path
	check(reload.load_save() and reload.data.total_gold==s.data.total_gold and reload.data.constellation_nodes==["comet_spark"],"All recovered transactions survive reload")
	# A failure at rename, after a successful temporary-file write.
	var rename_failure=Save.new()
	rename_failure.path="user://maintenance-rename-directory"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(rename_failure.path))
	var marker:=FileAccess.open(rename_failure.path+"/keep.txt",FileAccess.WRITE)
	marker.store_string("keep")
	marker.close()
	rename_failure.data.total_gold=1000
	check(not rename_failure.buy("might") and rename_failure.data.total_gold==1000 and rename_failure.data.meta_powerups.is_empty(),"Actual rename failure rolls back the transaction")
	check(FileAccess.get_file_as_string(rename_failure.path+"/keep.txt")=="keep","Rename failure cannot destroy the existing destination")
	# Discovery is real earned progress, retained in RAM and retried without rewards.
	block_write(s)
	s.mark_seen("prism_disc")
	s.mark_evolved("star_piercer")
	check(not s.save() and s.pending_write and s.discovered("prism_disc","weapon") and s.discovered("star_piercer","evolution"),"Failed discovery write keeps earned pending progress")
	before=s.data.duplicate(true)
	check(not s.buy("might") and s.pending_write and s.data==before,"Failed purchase cannot erase earlier pending discoveries")
	check(not s.reset_all() and s.pending_write and s.data==before,"Failed reset also preserves pending discoveries")
	unblock(s)
	check(s.save() and not s.pending_write and s.warning.is_empty(),"Progress retry clears pending/error only on successful save")
	reload.load_save()
	check(reload.discovered("prism_disc","weapon") and reload.discovered("star_piercer","evolution"),"Retried discoveries survive restart")
	var app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://maintenance-ui.json"
	root.add_child(app)
	app.save.data.total_gold=1000
	block_write(app.save)
	app.save.buy("might")
	app.shop()
	app.set_process(false)
	app._process(0)
	check(app.save_feedback_label.text.contains("Could not save this upgrade") and app.save.data.total_gold==1000,"Shop displays real purchase error without spending gold")
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.save.persistent=true
	app.model.upgrade("prism_disc")
	app._process(0)
	check(app.save.pending_write and app.save_notice.text.contains("Pause to retry"),"Failed inventory discovery is visible during gameplay")
	app.pause_game()
	check(app.save_retry_button.visible and paused,"Pause provides a reachable pending-progress retry")
	await process_frame
	check(root.gui_get_focus_owner()==app.save_retry_button,"Pending progress retry receives keyboard/controller focus")
	unblock(app.save)
	app.save_retry_button.pressed.emit()
	check(not app.save.pending_write and app.state=="PAUSED" and paused,"Retry preserves pause/session state")
	app.save.persistent=false
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("Maintenance checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
