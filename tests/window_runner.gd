extends SceneTree
var failed: bool=false
func _initialize() -> void:
	call_deferred("run")
func check(value: bool,message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value: failed=true
func run() -> void:
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	var embedded: bool=app.window_settings.embedded(root)
	var previous: int=app.window_settings.requests
	for i in range(10): app.set_setting("music",float(i)/10)
	check(app.window_settings.requests==previous,"Ten audio changes cause no native window requests")
	if embedded:
		app.set_setting("resolution",0)
		app.set_setting("fullscreen",true)
		check(app.window_settings.requests==0,"Embedded window ignores native size and fullscreen requests")
		app.settings()
		print("PASS Embedded settings explain editor ownership of window size")
	else:
		check(root.size==Vector2i(1920,1080),"Default native window is 1920x1080")
		for index in [0,1,2]:
			app.set_setting("resolution",index)
			await process_frame
			await process_frame
			check(root.size==app.window_settings.RESOLUTIONS[index],"Native resize to "+str(app.window_settings.RESOLUTIONS[index]))
	app.queue_free()
	await create_timer(.25,true).timeout
	quit(1 if failed else 0)
