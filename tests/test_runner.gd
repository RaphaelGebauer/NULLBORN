extends SceneTree
var failures: int=0
func check(value: bool, message: String) -> void:
	if value: print("PASS ",message)
	else:
		push_error("FAIL "+message)
		failures+=1
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model=load("res://scripts/run_model.gd").new()
	check(model.hp==100 and model.weapons.size()==1,"Standardheld")
	check(model.required_xp()==8,"XP-Startkurve")
	var requests: Array=[]
	model.modal_requested.connect(func(kind): requests.append(kind))
	model.add_xp(100,false)
	check(requests.size()>1 and model.xp>=0,"XP-Overflow und Level-Queue")
	var offers: Array=model.offers()
	check(offers.size()==3 and offers[0]!=offers[1] and offers[1]!=offers[2] and offers[0]!=offers[2],"Drei eindeutige Karten")
	model.heal(1000)
	check(model.hp==100,"Heilungsdeckel")
	var scene=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(scene)
	scene.start_run()
	var e: Dictionary=scene.world.spawn_enemy("wisp",Vector2(80,0))
	for i in range(100):
		scene.world._physics_process(0.016)
	check(e.hp<=0 and scene.model.kills>=1,"Echtes automatisches Projektil tötet Gegner")
	scene.model.hurt(1000)
	check(scene.state=="DEFEAT","Tod und Ergebnis")
	scene.queue_free()
	await process_frame
	print("Ergebnis: ",failures," Fehler")
	quit(1 if failures else 0)
