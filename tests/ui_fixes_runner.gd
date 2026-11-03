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
	check(map.selected=="veil_seed" and map.purchase.disabled and map.purchase.text=="Unlocked" and map.nodes.veil_seed.text.begins_with("✦"),"Bought star stays selected with Owned state")
	map.buy_selected()
	check(map.detail.text.contains("Already unlocked."),"Owned restriction is precise")
	map.select("last_star")
	check(map.detail.text.contains("Requires: Still Heart"),"Prerequisite takes priority over insufficient currency")
	map.select("quiet_pulse")
	check(map.detail.text.contains("Not enough Starlight (1 / 2)."),"Unaffordable selection states exact cost and wallet")
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
	app.model=load("res://scripts/run_model.gd").new()
	app.save.data.evolved_recipes=[]
	app.model.weapons={"arcane_needle":1}
	app.model.passives={}
	check(app.pause_recipe_text().begins_with("No matching evolution recipes"),"Weapon without catalyst matches zero recipes")
	app.model.weapons.arcane_needle=3
	app.model.passives={"power_core":2}
	check(app.pause_recipe_text().begins_with("1 matching evolution recipe · 0 ready"),"All components below thresholds match but are not ready")
	app.model.weapons.arcane_needle=5
	app.model.passives.power_core=5
	text=app.pause_recipe_text()
	check(text.begins_with("1 matching evolution recipe · 1 ready") and not text.contains("Star Piercer") and not text.contains("Power Core"),"Ready unknown recipe reveals count only")
	check(not app.model.evolution(false) and app.model.weapons.has("arcane_needle"),"UI readiness never bypasses chest eligibility")
	app.model.weapons={"ash_bow":5,"frost_shard":5}
	app.model.passives={"runner_boots":5}
	var fusion: Resource=app.catalog.get_def("dusk_storm")
	check(app.model.recipe_matches(fusion,true),"Fusion requires both bases and catalyst at required levels")
	var expected: int=0
	for recipe in app.catalog.catalogs.evolution.values():
		if app.model.recipe_matches(recipe): expected+=1
	check(app.pause_recipe_text().begins_with(str(expected)+" matching evolution recipe"),"Recipe candidates counted once each including fusion")
	app.model.weapons.erase("frost_shard")
	check(not app.model.recipe_matches(fusion),"Missing fusion component cannot match")
	app.model.weapons.frost_shard=5
	var before: Array=[app.model.time,app.model.xp,app.model.rng.state,app.model.weapons.duplicate(true)]
	app.pause_recipe_text()
	check(before==[app.model.time,app.model.xp,app.model.rng.state,app.model.weapons],"Recipe reporting leaves gameplay and RNG untouched")
	check(app.model.evolution(true)=="dusk_storm","Actual eligible chest still prioritizes fusion")
	check(not app.model.recipe_matches(fusion) and not app.model.weapons.has("ash_bow") and not app.model.weapons.has("frost_shard"),"Consumed bases and completed recipe cannot count again")
	app.save.mark_evolved("dusk_storm")
	check(app.pause_recipe_text().contains(fusion.display_name) and app.pause_recipe_text().contains("consumed"),"Actually discovered recipes retain detailed requirements")
	app.save.persistent=false
	app.menu()
	app.return_to_pause=false
	app.settings()
	check(app.state=="SETTINGS" and not paused,"Main menu Settings has a distinct navigation state")
	for child in app.panel.get_children():
		if child is Button and child.text=="Back": child.pressed.emit(); break
	check(app.state=="MENU" and not paused,"Settings Back returns to main menu")
	app.start_run()
	app.choose_rune(0)
	app.events=[]
	app.pause_game()
	app.return_to_pause=true
	app.settings()
	app.set_setting("music",.25)
	var snapshot: Array=[app.model.time,app.model.xp,app.model.kills,app.world.combat.elapsed,app.world.player.position]
	await create_timer(.1,true).timeout
	check(app.state=="SETTINGS" and paused and snapshot==[app.model.time,app.model.xp,app.model.kills,app.world.combat.elapsed,app.world.player.position],"Settings freezes run clock, attacks, XP and player movement")
	for child in app.panel.get_children():
		if child is Button and child.text=="Back": child.pressed.emit(); break
	await process_frame
	check(app.state=="PAUSED" and paused and root.gui_get_focus_owner() is Button,"Pause Settings Back returns paused with controller focus")
	await create_timer(.1,true).timeout
	check(snapshot==[app.model.time,app.model.xp,app.model.kills,app.world.combat.elapsed,app.world.player.position],"Returning to Pause keeps gameplay stopped")
	app.settings()
	await process_frame
	var cancel:=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	app._unhandled_input(cancel)
	await process_frame
	check(app.state=="PAUSED" and paused and app.save.data.settings.music==.25,"Settings Esc returns to Pause and preserves settings")
	app._unhandled_input(cancel)
	await create_timer(.1,true).timeout
	check(app.state=="RUNNING" and not paused and app.model.time>float(snapshot[0]),"Explicit Pause cancel resumes simulation")
	app.save.persistent=false
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("UI fixes checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
