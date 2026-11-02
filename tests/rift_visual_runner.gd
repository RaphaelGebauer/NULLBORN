extends SceneTree
var app: Node
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	app.world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/workspace/NULLBORN/docs/screenshots/"+name+".png")
	print("CAPTURE ",name," ",root.size)
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.model.time=360
	app.model.instability=75
	app.events=[]
	app.world.rifts.update()
	app.world.player.position=app.world.rifts.node.pos+Vector2(-60,0)
	app.world.player.get_node("Camera2D").reset_smoothing()
	var e: Dictionary=app.world.spawn_enemy(app.model.registry.get_def("wave_06").values.weights.keys()[0],app.world.player.position+Vector2(160,80))
	app.world.elite_director.promote(e,["blinking"])
	app.world.elite_director.update(e,7)
	root.size=Vector2i(1280,720)
	app._process(.01)
	await capture("rift-node")
	app.world.rifts.interact()
	app.show_event()
	root.size=Vector2i(1600,900)
	await capture("rift-decision")
	app.choose_rift(false)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.model.time=1200
	var boss: Dictionary=app.world.spawn_enemy("astral_guardian",app.world.player.position+Vector2(160,-70))
	boss.hp=boss.max_hp*.5
	app.world.bosses.update(boss,Vector2.LEFT,.01)
	root.size=Vector2i(1920,1080)
	app._process(.01)
	await capture("boss-phase-two")
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	quit()
