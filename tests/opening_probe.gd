extends SceneTree
# Informational three-minute opening probe: no immunity, healing or damage overrides.
# Scripted circular movement at actual Model speed and automatic legal choices are not human balance proof.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	for hero in ["lyra","brann","eira","noctis"]:
		for previous in [true,false]:
			var model=load("res://scripts/run_model.gd").new()
			model.rng.seed=115
			model.hero=hero
			model.weapons={model.registry.get_def(hero).values.weapon:1}
			model.pacing=model.pacing.duplicate(true)
			if previous:
				model.pacing.values.player_speed=.7125
				model.pacing.values.normal_enemy_hp=1.0
			model.recalculate()
			model.add_rune("time_anchor")
			var world=load("res://scenes/game.tscn").instantiate()
			world.model=model
			root.add_child(world)
			world.set_physics_process(false)
			world.player.set_physics_process(false)
			world.player.get_node("Camera2D").position_smoothing_enabled=false
			var events: Array=[]
			model.modal_requested.connect(func(kind):events.append(kind))
			model.mutation_requested.connect(func(id):events.append("MUTATION:"+id))
			var first_hit: float=-1
			var minimum_hp: float=model.hp
			var peak_enemies: int=0
			var angle: float=0
			for frame in range(5400):
				angle+=model.speed/240.0/30
				world.player.position=Vector2.RIGHT.rotated(angle)*240
				world.player.invulnerable=maxf(0,world.player.invulnerable-1.0/30)
				world.player.get_node("Camera2D").force_update_scroll()
				world._physics_process(1.0/30)
				if first_hit<0 and model.statistics.damage_taken>0: first_hit=model.time
				minimum_hp=minf(minimum_hp,model.hp)
				peak_enemies=maxi(peak_enemies,world.enemies.size())
				while not events.is_empty() and not model.finished:
					var kind: String=events.pop_front()
					if kind=="LEVELUP": model.upgrade(model.offers()[0])
					if kind.begins_with("MUTATION:"):
						var id: String=kind.get_slice(":",1)
						model.select_mutation(id,model.registry.mutation_choices(id)[0].id)
				if model.finished: break
			print("OPENING ",hero," ","previous" if previous else "current"," · run seconds ",snappedf(model.time,.01)," · min/final HP ",snappedf(minimum_hp,.01),"/",snappedf(model.hp,.01)," · damage taken ",model.statistics.damage_taken," · first hit ",snappedf(first_hit,.01)," · peak enemies ",peak_enemies," · kills ",model.kills," · level ",model.level)
			world.queue_free()
			await process_frame
			await process_frame
	quit()
