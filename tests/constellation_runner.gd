extends SceneTree
const Stars=preload("res://scripts/data/constellations.gd")
const Model=preload("res://scripts/run_model.gd")
const Save=preload("res://scripts/save_manager.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok:
		passes+=1
		print("PASS ",message)
	else:
		failures+=1
		push_error("FAIL "+message)
func run() -> void:
	check(Stars.validate().is_empty() and Stars.NODES.size()==18,"Eighteen unique valid nodes across three complete paths")
	var save=Save.new()
	save.path="user://constellation-test.json"
	save.data.starlight=63
	save.data.total_gold=321
	save.data.meta_powerups={"speed":2}
	check(not save.buy_star("far_traveler") and save.data.starlight==63,"Cannot skip prerequisites")
	var spent: int=0
	for id in Stars.NODES:
		var d: Dictionary=Stars.NODES[id]
		check(save.star_available(id) and save.buy_star(id),"Purchase correct chain: "+id)
		spent+=d.rank
		check(save.data.starlight==63-spent and not save.buy_star(id),"Exact cost and no duplicate purchase: "+id)
	var loaded=Save.new()
	loaded.path=save.path
	check(loaded.load_save() and loaded.data.constellation_nodes.size()==18 and loaded.data.starlight==0,"All stars persist across restart")
	check(loaded.data.total_gold==321 and loaded.data.meta_powerups.speed==2,"Star transactions preserve existing gold and meta")
	check(not loaded.buy_star("unknown") and not loaded.buy_star("comet_spark"),"Invalid and unaffordable purchases are safe")
	var failed=Save.new()
	failed.path="user://missing-star-directory/save.json"
	failed.data.starlight=10
	check(not failed.buy_star("comet_spark") and failed.data.starlight==10 and failed.data.constellation_nodes.is_empty() and not failed.warning.is_empty(),"Failed purchase rolls back currency and node")
	var model=Model.new()
	model.time=1800
	model.bosses=99
	model.instability=100
	check(Stars.reward(model,true)==8 and Stars.reward(model,false)==5,"Reward capped at eight; defeat retains earned points")
	loaded.persistent=false
	loaded.finish_run(model,true)
	loaded.finish_run(model,true)
	check(loaded.data.starlight==8 and loaded.data.stats.runs==1,"Run rewards credited once")
	var retry=Model.new()
	retry.bosses=1
	failed.finish_run(retry,false)
	check(not retry.banked and failed.data.starlight==10 and failed.data.stats.runs==0,"Failed result save rolls back all rewards and remains retryable")
	failed.path="user://retry-star-test.json"
	failed.finish_run(retry,false)
	failed.finish_run(retry,false)
	check(retry.banked and failed.data.starlight==11 and failed.data.stats.runs==1,"Retry awards once after storage recovers")
	check(loaded.reset_all() and loaded.data.starlight==0 and loaded.data.constellation_nodes.is_empty(),"Full reset clears star progression")
	var base=Model.new()
	base.recalculate()
	for id in ["comet_spark","gathering_tail","swift_orbit","astral_insight","far_traveler","veil_seed","quiet_pulse"]:
		model=Model.new()
		model.constellation_nodes=[id]
		model.recalculate()
		var works: bool=false
		match id:
			"comet_spark": works=is_equal_approx(model.speed,base.speed+model.speed_base*.01)
			"far_traveler": works=is_equal_approx(model.speed,base.speed+model.speed_base*.01) and model.magnet==base.magnet+6
			"gathering_tail": works=model.magnet==base.magnet+6
			"swift_orbit": works=is_equal_approx(model.projectile_speed,base.projectile_speed+.03)
			"astral_insight": works=is_equal_approx(model.growth,base.growth+.02)
			"veil_seed": works=model.max_hp==base.max_hp+3
			"quiet_pulse": works=is_equal_approx(model.regeneration,.05)
		check(works,"Real stat bonus: "+id)
		var snapshot: Array=[model.speed,model.magnet,model.projectile_speed,model.growth,model.max_hp,model.regeneration]
		for i in range(20): model.recalculate()
		check(snapshot==[model.speed,model.magnet,model.projectile_speed,model.growth,model.max_hp,model.regeneration],"No recalculation stacking: "+id)
	model=Model.new()
	model.constellation_nodes=["rush_of_stars","still_heart","last_star"]
	model.recalculate()
	var normal_speed: float=model.speed
	model.boss_killed()
	check(is_equal_approx(model.speed,normal_speed+model.speed_base*.02),"Rush of Stars real movement")
	model.time=10
	model.boss_killed()
	check(model.rush_until==30 and is_equal_approx(model.speed,normal_speed+model.speed_base*.02),"Rush refresh never stacks")
	model.time=30
	model.update_movement_speed()
	check(model.speed==normal_speed,"Rush expires")
	model.hp=40
	model.time=299.9
	model.tick(.1)
	check(model.hp==42,"Still Heart heals exactly at five-minute boundary")
	model.tick(.1)
	check(model.hp==42,"Still Heart does not repeat every frame")
	model.hp=50
	model.time=599.9
	model.tick(.1)
	check(model.hp==50,"Still Heart requires below half HP")
	model.hp=30
	model.hurt(10)
	check(model.hp==28 and model.last_star_used,"Last Star heals once below 25 percent")
	model.hurt(10)
	check(model.hp==18,"Last Star cannot retrigger")

	for quick in [false,true]:
		var heart=Model.new()
		heart.constellation_nodes=["still_heart"]
		heart.fast=quick
		heart.hp=30
		for i in range(6): heart.tick(150 if quick else 300)
		check(heart.still_heart_boundary==6 and heart.statistics.total_healing==12 and heart.time==1800,"Six exact Still Heart opportunities; quick="+str(quick))
	var dead=Model.new()
	dead.constellation_nodes=["last_star"]
	dead.hurt(1000)
	check(dead.hp==0 and dead.finished and not dead.last_star_used,"Last Star cannot resurrect")
	model=Model.new()
	model.constellation_nodes=Stars.NODES.keys()
	model.recalculate()
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	model.time=360
	model.instability=50
	model.hp=40
	world.rifts.update()
	world.player.position=world.rifts.node.pos
	world.rifts.interact()
	world.rifts.choose(false)
	check(model.instability==27 and is_equal_approx(model.hp,40+model.max_hp*.1+4),"Clear Horizon and Second Breath affect real stabilization")
	model.time=720
	world.rifts.update()
	world.player.position=world.rifts.node.pos
	world.rifts.interact()
	var xp: float=model.required_xp()*.35*1.05
	world.rifts.choose(true)
	check(is_equal_approx(model.xp,xp),"Risk Seeker applies once without Growth")
	model.time=900
	model.instability=50
	var e: Dictionary=world.spawn_enemy(model.registry.get_def("wave_15").values.weights.keys()[0],Vector2(300,0))
	world.elite_director.promote(e,["armored"])
	model.crit=0
	var hp: float=e.hp
	world.hit(e,100,{},"prism_disc")
	check(hp-e.hp==round(100*1.03*.8),"Hunter's Star only boosts elite direct hits once")
	e.hp=0
	world.kill_enemy(e)
	check(world.pickups.any(func(p):return p.kind=="gold" and p.value==round(45*1.2*1.05)),"Tainted Treasure boosts actual elite gold at threshold")
	var boss: Dictionary=world.spawn_enemy("astral_guardian",Vector2(400,0))
	model.instability=75
	hp=boss.hp
	world.hit(boss,100,{},"prism_disc")
	check(hp-boss.hp==103,"Fracture Mastery boosts boss at Unstable")
	model.instability=74
	hp=boss.hp
	world.hit(boss,100,{},"prism_disc")
	check(hp-boss.hp==100,"Fracture Mastery has no global/low-instability bonus")
	world.shots.clear()
	world.player.invulnerable=0
	model.hp=model.max_hp
	model.last_star_used=true # Isolate projectile reduction from the separate emergency-heal test.
	hp=model.hp
	world.projectile(world.player.position,Vector2.ZERO,{"damage":100,"boss":true},"boss",0,true)
	world.update_shots(.01)
	check(hp-model.hp==97,"Guarded Orbit mitigates actual boss projectile")

	model.instability=75
	var proc_target: Dictionary=world.spawn_enemy("astral_guardian",Vector2(600,0))
	hp=proc_target.hp
	world.hit(proc_target,100,{},"prism_disc",true)
	check(hp-proc_target.hp==103,"Fracture Mastery affects fresh secondary hits")
	hp=proc_target.hp
	world.hit(proc_target,103,{},"prism_disc",true,Vector2.INF,1.03)
	check(hp-proc_target.hp==103,"Derived secondary cannot double-apply the target bonus")
	var ordinary: Dictionary=world.spawn_enemy("guardian",Vector2(700,0))
	ordinary.hp=1000
	world.hit(ordinary,103,{},"prism_disc",true,Vector2.INF,1.03)
	check(ordinary.hp==900,"Derived elite/boss damage bonus cannot leak to normal secondary recipients")
	world.enemies.clear()
	world.combat.effects.clear()
	model.instability=75
	var primary: Dictionary=world.spawn_enemy("astral_guardian",Vector2(100,0))
	primary.hp=10000
	var neighbor: Dictionary=world.spawn_enemy("guardian",Vector2(120,0))
	neighbor.hp=10000
	world.grid.rebuild(world.enemies)
	world.hit(primary,100,{},"frost_shard")
	var bonus_before: float=model.statistics.damage_by_source.get("Elemental Reactions",0)
	world.hit(primary,100,{},"lightning_call")
	check(model.statistics.damage_by_source.get("Elemental Reactions",0)-bonus_before==48 and neighbor.hp==9970,"Reaction keeps boss primary bonus once and removes it from normal chain target")
	world.combat.modifiers.secondary("prism_disc",neighbor.pos,15,103,0,1,primary.id,1.03)
	world.combat.update(.01)
	check(neighbor.hp==9870,"Mutation pulse forwards inherited target factor through pooled effect")
	world.queue_free()
	await process_frame
	await process_frame
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.save.data.starlight=5
	app.star_map()
	var map=app.panel.get_child(2)
	check(map.nodes.size()==18 and map.nodes.comet_spark.tooltip_text.contains("Requires:"),"Real star map creates all nodes and descriptive tooltips")
	map.select("comet_spark")
	map.buy_selected()
	check(app.save.data.constellation_nodes==["comet_spark"],"Star map purchase uses real save transaction")
	map.nodes.veil_seed.grab_focus()
	check(map.selected=="comet_spark","Keyboard/controller focus alone preserves selection")
	map.nodes.veil_seed.pressed.emit()
	check(map.selected=="veil_seed" and map.detail.text.contains("Maximum HP +3"),"Keyboard/controller confirmation updates inspector")
	app.start_run()
	app.save.data.constellation_nodes.append("veil_seed")
	check(app.model.constellation_nodes==["comet_spark"],"Run snapshot isolated from subsequent purchases")
	check(app.instability_details().find("Next threshold")==-1,"Next threshold hidden without Rift Sense")
	app.model.constellation_nodes.append("rift_sense")
	check(app.instability_details().contains("Next threshold"),"Rift Sense reveals next threshold")
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("Constellation checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
