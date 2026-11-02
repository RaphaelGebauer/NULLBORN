extends SceneTree
var app: Node
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var directory: String=OS.get_environment("STERNENBRUCH_CAPTURE_DIR")
	if directory.is_empty(): directory="user://mutation_captures"
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory+"/"+name+".png")
	print("CAPTURE ",name," · ",root.size)
func pause_game() -> void:
	var event:=InputEventAction.new()
	event.action="ui_cancel"
	event.pressed=true
	app._unhandled_input(event)
func run() -> void:
	app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.model.weapons={"arcane_needle":3}
	app.model.passives={"power_core":5}
	app.events=[]
	app.state="LEVELUP"
	app.cards=["arcane_needle","reward_gold","reward_heal"]
	app.choose(0)
	root.size=Vector2i(1280,720)
	await capture("mutation-choice-1280")
	app.choose_mutation(0)
	app.model.upgrade("arcane_needle")
	assert(app.model.evolution(true)=="star_piercer")
	pause_game()
	root.size=Vector2i(1600,900)
	await capture("inherited-evolution-1600")
	app.resume()
	app.model.weapons={"ash_bow":5,"frost_shard":5}
	app.model.passives={"runner_boots":5}
	app.model.weapon_mutations={}
	app.model.ensure_mutations()
	app.show_event()
	app.choose_mutation(0)
	app.choose_mutation(0)
	assert(app.model.evolution(true)=="dusk_storm")
	pause_game()
	root.size=Vector2i(1920,1080)
	await capture("fusion-imprints-1920")
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	quit()
