extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model=load("res://scripts/run_model.gd").new()
	model.weapons={"star_piercer":1,"solar_orbit":1,"blood_thorns":1,"zenith_beam":1,"night_storm":1,"ghost_well":1}
	model.passives={"power_core":5,"clockwork":5,"focus_lens":5,"lasting_seal":5,"multiplicity":5,"blood_vial":5}
	model.recalculate()
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	world.damage_texts=false
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var events: Array=["RUNE"]
	var outcomes: Array=[]
	model.modal_requested.connect(func(kind):events.append(kind))
	model.ended.connect(func(won):outcomes.append(won))
	var start: int=Time.get_ticks_msec()
	var counts: Array=[]
	for frame in range(54002):
		world.player.invulnerable=1
		world.player.position=Vector2(sin(frame*.003),cos(frame*.003))*350
		world._physics_process(1.0/30)
		# Harness resolves choices through real inventory logic; modal UI has a separate pause test.
		while not events.is_empty():
			var kind: String=events.pop_front()
			if kind=="LEVELUP": model.upgrade(model.offers()[0])
			if kind=="RUNE":
				for id in ["treasure","time_anchor","ice_crown"]:
					if not id in model.runes:
						model.add_rune(id)
						break
			if kind.begins_with("CHEST"): model.evolution(kind=="CHEST_EVOLUTION")
		if frame%9000==0:
			counts.append([world.enemies.size(),world.shots.size(),world.pickups.size()])
			print("RUN ",int(model.time)," s · ",counts[-1]," · Kills ",model.kills)
		if model.finished: break
	var valid: bool=model.finished and outcomes==[true] and world.minute==29 and model.runes.size()==3
	print("PASS" if valid else "FAIL"," voller 30-Minuten-Run; Zeit ",model.time,"; Ergebnis ",outcomes,"; Runen ",model.runes.size(),"; Laufzeit ",(Time.get_ticks_msec()-start)/1000.0," s; Kills ",model.kills)
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if valid else 1)
