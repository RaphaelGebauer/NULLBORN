extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.save.data.starlight=8
	app.save.data.constellation_nodes=["comet_spark","veil_seed","quiet_pulse"]
	for resolution in [Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]:
		root.size=resolution
		app.star_map()
		var map=app.panel.get_child(2)
		map.select("guarded_orbit")
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/workspace/NULLBORN/docs/screenshots/star-map-%d.png"%resolution.x)
		print("CAPTURE Star Map ",resolution)
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	quit()
