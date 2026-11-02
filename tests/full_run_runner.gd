extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var model=load("res://scripts/run_model.gd").new()
	var evolved: Dictionary={}
	var imprints: Dictionary={}
	for id in ["star_piercer","solar_orbit","blood_thorns","zenith_beam","night_storm","ghost_well"]:
		var recipe: Resource=model.registry.get_def(id)
		var base: String=recipe.values.bases[0]
		model.weapons={base:5}
		model.passives={recipe.values.passive:5}
		model.ensure_mutations()
		model.select_mutation(base,model.registry.mutation_choices(base)[0].id)
		assert(model.evolution(true)==id)
		evolved[id]=1
		imprints[id]=model.weapon_mutations[id].duplicate(true)
	model.weapons=evolved
	model.weapon_mutations=imprints
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
	var phase_changes: Array=[]
	model.boss_phase_changed.connect(func(kind,phase):phase_changes.append([kind,phase]))
	for frame in range(54002):
		world.player.invulnerable=1
		world.player.position=Vector2(sin(frame*.003),cos(frame*.003))*350
		world._physics_process(1.0/30)
		if not world.rifts.node.is_empty() and not world.rifts.node.pending:
			world.player.position=world.rifts.node.pos
			world.rifts.interact()
		# Harness resolves choices through real inventory logic; modal UI has a separate pause test.
		while not events.is_empty():
			var kind: String=events.pop_front()
			if kind=="RIFT": world.rifts.choose(world.rifts.slots_used%2==0)
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
	var valid: bool=model.finished and outcomes==[true] and world.minute==29 and model.runes.size()==3 and model.weapon_mutations.size()==6 and model.rifts_stabilized==2 and model.rifts_overcharged==2 and model.elite_kills>0 and not phase_changes.is_empty() and world.reactions.events_total>0
	print("PASS" if valid else "FAIL"," voller 30-Minuten-Run; Zeit ",model.time,"; Ergebnis ",outcomes,"; Runen ",model.runes.size(),"; Laufzeit ",(Time.get_ticks_msec()-start)/1000.0," s; Kills ",model.kills)
	print("E3: boss phase transitions ",phase_changes,"; elites ",model.elite_kills,"; affixes ",model.affixes_seen,"; rifts ",model.rifts_stabilized,"/",model.rifts_overcharged,"; peak/final instability ",model.rift_state.peak,"/",model.instability)
	print("E4: reactions ",world.reactions.events_total,"; by kind ",world.reactions.counts,"; damage ",model.statistics.damage_by_source.get("Elemental Reactions",0))
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if valid else 1)
