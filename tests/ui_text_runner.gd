extends SceneTree
const Stars=preload("res://scripts/data/constellations.gd")
var app: Node
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func labels(node: Node) -> String:
	var text: String=node.text+"\n" if node is Label else ""
	for child in node.get_children(): text+=labels(child)
	return text
func settle() -> void:
	for i in range(4): await process_frame
func capture(name: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/screenshots/text-"+name+".png"))
func actions_fit() -> bool:
	return app.detail_actions.get_children().all(func(n):return root.get_visible_rect().encloses(n.get_global_rect()))
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://ui-text-only.json"
	root.add_child(app)
	app.save.persistent=false
	app.save.data.constellation_nodes=[]
	app.save.data.starlight=0
	app.star_map()
	var map=app.panel.get_child(2)
	var clean: bool=true
	for id in Stars.NODES:
		map.select(id)
		map.buy_selected()
		var previous: String=Stars.predecessor(id)
		clean=clean and map.detail.text.count("Requires:")==(0 if previous.is_empty() else 1)
		clean=clean and map.detail.text.contains(Stars.NODES[id].effect) and map.detail.text.contains("%d Starlight" % Stars.NODES[id].rank)
	check(clean and app.save.warning.is_empty(),"All 18 locked stars retain effects/costs and at most one requirement; hints stay local")
	check(Stars.PATHS[1]=="Constellation of Veil","Veil display name preserves technical IDs")
	app.save.data.constellation_nodes=["veil_seed"]
	map.select("quiet_pulse")
	check(map.detail.text.contains("Not enough Starlight (0 / 2).") and map.detail.text.count("Requires:")==1,"Wallet and prerequisite shown once each")
	app.save.data.starlight=10
	map.buy_selected()
	check(map.purchase.disabled and map.detail.text.count("Already unlocked.")==1,"Unlocked state has one precise message")
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.events=[]
	app.model.weapons={"arcane_needle":5,"ash_bow":5,"frost_shard":5,"gravity_mine":5,"reaper_gaze":5,"lightning_call":5}
	app.model.passives={"power_core":5,"runner_boots":5,"blood_vial":5,"recovery_moss":5,"execution_seal":5,"momentum_feather":5}
	app.model.recalculate()
	app.save.mark_evolved("star_piercer")
	app.pause_game()
	check(not labels(app.panel).contains("90 px") and not labels(app.panel).contains("Star Piercer") and app.pause_recipe_text().contains("Star Piercer") and app.pause_recipe_text().contains("10:00+"),"Pause keeps recipe counts; discovered requirements and chest gate live in Build")
	check(not app.instability_details().contains("Enemy density") and app.instability_details(true).contains("Enemy density"),"Instability factors move to Build; schedule and lifetime stay in Pause")
	app.world.rifts.node={"pos":app.world.player.position}
	app.resume()
	app._process(0)
	check(app.instability_label.text.contains("[F / Y] Rift Node"),"Rift input help appears in range")
	app.world.rifts.node={}
	app._process(0)
	check(not app.instability_label.text.contains("[F / Y]"),"Rift input help disappears out of context")
	if DisplayServer.get_name()!="headless":
		for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
			root.size=resolution
			app.star_map()
			map=app.panel.get_child(2)
			var fit: bool=true
			for id in Stars.NODES:
				map.select(id)
				await settle()
				fit=fit and map.detail.get_minimum_size().y<=map.detail.size.y and root.get_visible_rect().encloses(map.detail.get_global_rect())
			check(fit,"All 18 star inspectors wrap without clipping "+str(resolution))
			map.select("last_star")
			await capture("star-%d" % resolution.x)
			app.pause_game()
			await capture("pause-%d" % resolution.x)
			check(root.get_visible_rect().encloses(app.panel.get_global_rect()),"Full six-slot Pause fits "+str(resolution))
			app.build_details()
			await capture("build-%d" % resolution.x)
			check(actions_fit(),"Build actions fit "+str(resolution))
			app.model.finished=true
			app.result(false)
			await capture("result-%d" % resolution.x)
			check(actions_fit() and app.panel.size.x<=root.get_visible_rect().size.x,"Defeat report and actions fit "+str(resolution))
			app.model.finished=false
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	await settle()
	print("UI text checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
