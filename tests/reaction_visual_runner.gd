extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.model.crit=0
	app.model.weapons={}
	var positions: Array=[Vector2(-220,-100),Vector2(100,-100),Vector2(-220,100),Vector2(100,100)]
	var sources: Dictionary={"frost":"frost_shard","storm":"spark_orbit","fire":"ash_bow","toxin":"thorn_halo","void":"soul_well"}
	for i in range(4):
		var d: Dictionary=app.world.reactions.DEFINITIONS[i]
		var e: Dictionary=app.world.spawn_enemy("guardian",positions[i])
		e.hp=1000
		e.max_hp=1000
		app.world.spawn_enemy("wisp",positions[i]+Vector2(40,0))
		app.world.grid.rebuild(app.world.enemies)
		app.world.hit(e,50,{},sources[d.elements[0]])
		app.world.hit(e,50,{},sources[d.elements[1]])
	root.size=Vector2i(1280,720)
	app._process(.01)
	app.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/NULLBORN/docs/screenshots/element-reactions.png")
	print("CAPTURE all four actual reactions at 1280x720; events ",app.world.reactions.events_total)
	app.model.finish(false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/NULLBORN/docs/screenshots/reaction-result.png")
	print("CAPTURE actual reaction damage result")
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	quit()
