extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const Report=preload("res://scripts/run_report.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func snapshot(app: Node) -> PackedByteArray:
	return var_to_bytes([app.model.time,app.model.statistics.combat_seconds,app.model.xp,app.model.gold,app.model.rng.state,app.model.weapons,app.model.passives,app.world.enemies,app.world.shots,app.world.combat.elapsed,app.world.player.position])
func run() -> void:
	for hero in ["lyra","brann","eira","noctis"]:
		var model=Model.new()
		model.hero=hero
		model.recalculate()
		var previous: float=model.registry.get_def(hero).values.speed*.7125
		check(is_equal_approx(model.speed,previous*.8),"Current base movement ×0.8 for "+hero)
		for fast in [false,true]:
			model.fast=fast
			model.meta={"speed":2,"long_stride":2,"evasive_instinct":3}
			model.passives={"runner_boots":2,"momentum_feather":3}
			model.constellation_nodes=["comet_spark","far_traveler","rush_of_stars"]
			model.time=240
			model.hp=20
			model.rush_until=260
			model.recalculate()
			var speed: float=model.speed
			model.pacing=model.pacing.duplicate(true)
			model.pacing.values.player_speed=.7125
			model.recalculate()
			check(is_equal_approx(speed,model.speed*.8),"All additive speed bonuses retained; Quick="+str(fast)+" "+hero)
			model.pacing.values.player_speed=.57
			for i in range(20): model.recalculate()
			check(is_equal_approx(speed,model.speed),"Repeated recalculation never compounds speed "+hero)
	var loot_snapshots: Array=[]
	for factor in [1.0,1.2]:
		var loot_model=Model.new()
		loot_model.pacing=loot_model.pacing.duplicate(true)
		loot_model.pacing.values.normal_enemy_hp=factor
		loot_model.time=1200
		loot_model.rng.seed=115
		var loot_world=load("res://scenes/game.tscn").instantiate()
		loot_world.model=loot_model
		root.add_child(loot_world)
		loot_world.set_physics_process(false)
		loot_world.player.set_physics_process(false)
		for id in ["wisp","elite_hunter","astral_guardian"]:
			loot_world.kill_enemy(loot_world.spawn_enemy(id,Vector2(700,0)))
		var kind: String=loot_model.registry.get_def("wave_20").values.weights.keys().filter(func(id):return id!="splitter")[0]
		var elite: Dictionary=loot_world.spawn_enemy(kind,Vector2(700,0))
		loot_world.elite_director.promote(elite,["armored"])
		loot_world.kill_enemy(elite)
		loot_snapshots.append(var_to_bytes([loot_world.pickups,loot_model.kills,loot_model.bosses,loot_model.instability,loot_model.affixes_seen,loot_model.rng.state]))
		loot_world.queue_free()
		await process_frame
		await process_frame
	check(loot_snapshots[0]==loot_snapshots[1],"Actual normal/elite/boss kill rewards and RNG are identical under old/new HP factor")
	var model=Model.new()
	model.recalculate()
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	for minute in [0,17,29]:
		model.time=minute*60
		model.level=1 if minute==0 else 20
		model.curse=0 if minute==0 else .5
		model.instability=95
		var scaling: float=(1+.055*minute+.0025*minute*minute)*(1+.006*maxi(model.level-1,0))*(1+.1*floori(minute/5.0))*(1+model.curse)
		for id in model.registry.catalogs.enemy:
			var values: Dictionary=model.registry.get_def(id).values
			var enemy: Dictionary=world.spawn_enemy(id,Vector2(700,200))
			var expected: float=values.hp*scaling*(1.0 if values.boss else 1.2)
			check(is_equal_approx(enemy.hp,expected) and is_equal_approx(enemy.max_hp,expected),"Exactly one HP factor, boss exemption: %s at %d" % [id,minute])
			check(is_equal_approx(enemy.speed,values.speed*minf(1.35,1+.012*minute)*(1+.35*model.curse)) and is_equal_approx(enemy.damage,values.damage*(1+.035*minute)) and enemy.xp==values.xp,"Speed/damage/XP unchanged: "+id)
			world.enemies.erase(enemy)
			world.enemy_pool.append(enemy)
	model.time=0
	model.level=1
	model.curse=0
	model.instability=0
	model.time=1200
	model.instability=95
	for affixes in [["armored"],["armored","swift"],["armored","swift","hexbound"]]:
		var elite: Dictionary=world.spawn_enemy(model.registry.get_def("wave_20").values.weights.keys().filter(func(id):return id!="splitter")[0],Vector2(500,0))
		var base_hp: float=model.registry.get_def(elite.kind).values.hp*4.34
		check(world.elite_director.promote(elite,affixes) and is_equal_approx(elite.max_hp,base_hp*1.2*(2.5+.25*(affixes.size()-1))),"Existing elite multiplier after one new HP factor: "+str(affixes.size()))
		var hp: float=elite.max_hp
		check(not world.elite_director.promote(elite,affixes) and hp==elite.max_hp,"Repeated promotion cannot scale HP again")
	model.time=0
	var splitter: Dictionary=world.spawn_enemy("splitter",Vector2(700,0))
	world.kill_enemy(splitter)
	var children: Array=world.enemies.filter(func(e):return e.child)
	check(children.size()==2 and children.all(func(e):return is_equal_approx(e.max_hp,model.registry.get_def("mite").values.hp*1.2)),"Actual splitter children receive HP factor once")
	var queen: Dictionary=world.spawn_enemy("void_queen",Vector2(600,300))
	world.bosses.safe_summons(queen)
	children=world.enemies.filter(func(e):return e.parent_boss==queen.id)
	check(children.size()==3 and children.all(func(e):return is_equal_approx(e.hp,model.registry.get_def("mite").values.hp*1.2)),"Real Queen summons receive normal HP; boss keeps its HP")
	var enemy: Dictionary=world.spawn_enemy("guardian",Vector2(700,0))
	model.crit=0
	var hp: float=enemy.hp
	world.hit(enemy,100,{},"arcane_needle")
	check(hp-enemy.hp==100 and is_equal_approx(model.pacing.values.player_damage,.93),"Previous player damage factor unchanged; hit pipeline does not add HP scaling")
	world.queue_free()
	await process_frame
	await process_frame
	var app=load("res://scenes/main_menu.tscn").instantiate()
	app.save.path="user://layout-balance-test.json"
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.events=[]
	app.pause_game()
	check(app.equipment_view.weapon_grid.columns==6 and app.equipment_view.weapon_grid.get_child_count()==6 and app.equipment_view.passive_grid.get_child_count()==6,"Pause has two real rows of six slots")
	app.model.passives={"momentum_feather":2}
	app.model.inventory_changed.emit()
	check(app.equipment_view.passive_grid.get_child(0).tooltip_text.contains("Momentum Feather"),"Inventory signal refreshes projection without another inventory")
	app.model.runes=["blood_moon","time_anchor"]
	app.model.rune_changed.emit()
	check(app.equipment_view.rune_grid.get_child_count()==2,"Rune signal refreshes centered rune view")
	app.build_details()
	check(app.equipment_view.weapon_grid.columns==3 and app.equipment_view.passive_grid.columns==3,"Build equipment is two grids with three columns")
	check(app.detail_actions.get_child_count()==1 and app.detail_actions.get_child(0).text=="Back","Build has exactly one fixed Back action")
	var before: PackedByteArray=snapshot(app)
	await create_timer(.15,true).timeout
	app.build_details()
	await process_frame
	check(before==snapshot(app),"Build rendering and waiting preserve clocks, inventories, movement, attacks, XP, gold and RNG")
	app.detail_actions.get_child(0).pressed.emit()
	check(app.state=="PAUSED" and paused and before==snapshot(app),"Back returns to the same paused session")
	app.build_details()
	var cancel:=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	app._unhandled_input(cancel)
	check(app.state=="PAUSED" and paused and before==snapshot(app),"Esc/controller Back returns paused without simulation")
	app.model.weapons={"ash_bow":5,"frost_shard":5}
	app.model.passives={"runner_boots":5}
	app.model.ensure_mutations()
	for id in app.model.pending_mutations.duplicate(): app.model.select_mutation(id,app.catalog.mutation_choices(id)[0].id)
	check(app.model.evolution(true)=="dusk_storm","Real fusion still prioritizes both bases")
	var slots: Array=Report.equipment_slots(app.model,true)
	check(slots[0].kind=="Fusion" and slots[0].description.contains("Primary 100%") and slots[0].description.contains("Echo 50%") and slots.size()==6,"Grid data retains both fusion imprints, strengths and all slots")
	check(not str(Report.equipment_slots(Model.new(),true)).contains("Star Piercer"),"Equipment never reveals unknown recipes")
	app.events=[]
	app.menu()
	app.queue_free()
	await create_timer(.25,true).timeout
	print("Layout/balance checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
