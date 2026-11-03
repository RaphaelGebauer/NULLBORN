extends SceneTree
const Save=preload("res://scripts/save_manager.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func run() -> void:
	var app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://ui-fixes.json"
	root.add_child(app)
	app.save.persistent=false
	app.save.data.starlight=2
	app.star_map()
	var map=app.panel.get_child(2)
	var text: String=map.detail.text
	map.nodes.veil_seed.mouse_entered.emit()
	map.nodes.veil_seed.grab_focus()
	check(map.selected=="comet_spark" and map.detail.text==text,"Hover/focus leave selection and inspector unchanged")
	map.nodes.veil_seed.pressed.emit()
	check(map.selected=="veil_seed" and map.purchase.text=="Unlock · 1 Starlight","Pressed selects correct star and price")
	map.nodes.veil_seed.mouse_exited.emit()
	map.nodes.comet_spark.grab_focus()
	check(map.nodes.veil_seed.get_theme_stylebox("normal").border_width_left==3 and map.nodes.comet_spark.get_theme_stylebox("normal").border_width_left==1,"Persistent unique three-pixel selection ring survives pointer/focus movement")
	map.buy_selected()
	check(map.selected=="veil_seed" and map.purchase.disabled and map.purchase.text=="Owned" and map.nodes.veil_seed.text.begins_with("✦"),"Bought star stays selected with Owned state")
	map.buy_selected()
	check(map.detail.text.contains("This star is already unlocked."),"Owned restriction is precise")
	map.select("last_star")
	check(map.detail.text.contains("Requires Still Heart to be unlocked first."),"Prerequisite takes priority over insufficient currency")
	map.select("quiet_pulse")
	check(map.detail.text.contains("Not enough Starlight. Required: 2, Available: 1."),"Unaffordable selection states exact cost and wallet")
	map.buy_selected()
	check(app.save.warning.is_empty() and not app.save.pending_write,"Ordinary purchase hints never become global save warnings")
	app.menu()
	check(app.save_feedback_label.text.is_empty(),"Menu does not inherit purchase hints")
	app.star_map()
	map=app.panel.get_child(2)
	check(map.selected=="comet_spark" and not map.detail.text.contains("Required: 2"),"Reopening map clears previous local purchase message")
	app.save.persistent=true
	app.save.data.starlight=10
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(app.save.path+".tmp"))
	app.save.mark_seen("prism_disc")
	app.save.save()
	map.buy_selected()
	check(app.save.pending_write and app.save.warning.contains("Could not save this purchase") and not app.save.data.constellation_nodes.has("comet_spark"),"Failed purchase preserves pending progress and rolls back")
	app.save.buy_star("last_star")
	check(app.save.warning.contains("Could not save this purchase") and app.save.pending_write,"Invalid purchase cannot overwrite technical error or pending state")
	app.menu()
	check(app.save_retry_button.visible and app.save_feedback_label.text.contains("Could not save"),"Technical error and retry survive navigation")
	DirAccess.remove_absolute(app.save.path+".tmp")
	app.save_retry_button.pressed.emit()
	check(not app.save.pending_write and app.save.warning.is_empty(),"Real storage retry clears error after recovery")
	app.save.persistent=false
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("UI fixes checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
