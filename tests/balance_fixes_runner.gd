extends SceneTree
const Model=preload("res://scripts/run_model.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	if ok: passes+=1; print("PASS ",message)
	else: failures+=1; push_error("FAIL "+message)
func run() -> void:
	for hero in ["lyra","brann","eira","noctis"]:
		var model=Model.new()
		model.hero=hero
		model.recalculate()
		var old_speed: float=model.registry.get_def(hero).values.speed*.75
		check(is_equal_approx(model.speed,old_speed*.95),"Exactly proportional five percent reduction: "+hero)
		model.meta={"speed":3,"long_stride":2,"evasive_instinct":2,"might":2}
		model.passives={"runner_boots":3,"momentum_feather":2,"power_core":3}
		model.constellation_nodes=["comet_spark","far_traveler","rush_of_stars"]
		model.time=240
		model.hp=20
		model.rush_until=260
		model.recalculate()
		var current: float=model.speed
		var damage: float=model.might
		model.pacing=model.pacing.duplicate(true)
		model.pacing.values.player_speed=.75
		model.pacing.values.player_damage=1.0
		model.recalculate()
		check(is_equal_approx(current,model.speed*.95) and is_equal_approx(damage,model.might*.93),"Meta/passive/timed/low-health/star bonuses stay proportional: "+hero)
		model.pacing.values.player_speed=.7125
		model.pacing.values.player_damage=.93
		model.recalculate()
		for i in range(10): model.recalculate()
		check(is_equal_approx(current,model.speed) and is_equal_approx(damage,model.might),"No recalculation factor stacking: "+hero)
		model.speed_base=1000
		model.update_movement_speed()
		check(model.speed==500,"Existing speed ceiling retained: "+hero)
	var model=Model.new()
	model.recalculate()
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	model.crit=0
	for kind in ["weapon","evolution"]:
		for id in model.registry.catalogs[kind]:
			var v: Dictionary=model.registry.weapon_values(id,1)
			var adjusted: Dictionary=world.combat.params(v)
			check(is_equal_approx(adjusted.damage,v.damage*.93),"One Might damage factor for "+id)
	var e: Dictionary=world.spawn_enemy("crawler",Vector2(100,0))
	e.hp=10000
	e.max_hp=10000
	world.grid.rebuild(world.enemies)
	var raw: Dictionary=model.registry.weapon_values("frost_shard",1)
	var primary: float=world.combat.params(raw).damage
	world.hit(e,primary,{},"frost_shard")
	check(e.hp==10000-round(primary),"Actual hit and measured damage use adjusted weapon value")
	var before: float=model.statistics.damage_by_source.get("Elemental Reactions",0)
	world.hit(e,93,{},"lightning_call")
	check(model.statistics.damage_by_source.get("Elemental Reactions",0)-before==round(93*.35),"Reaction uses final reduced triggering hit without a second nerf")
	before=e.hp
	world.combat.modifiers.world=world
	world.combat.modifiers.budget=24
	world.combat.modifiers.secondary("frost_shard",e.pos,20,93*.5)
	world.combat.update(.01)
	check(before-e.hp==round(93*.5),"Derived mutation pulse avoids double nerf")
	check(is_equal_approx(model.base_player_damage(16),14.88) and is_equal_approx(model.base_player_damage(4),3.72),"Flat death-fire and status sources use the same central raw factor")
	var def: Dictionary=model.registry.get_def("crawler").values
	check(e.speed==def.speed and e.damage==def.damage and e.xp==def.xp and e.max_hp==10000,"Enemy movement/damage/XP definitions unchanged")
	var normal=Model.new()
	var quick=Model.new()
	quick.fast=true
	normal.tick(1)
	quick.tick(1)
	check(normal.time==1 and quick.time==2 and normal.required_xp()==quick.required_xp(),"Normal/Quick clock and XP curve unchanged")
	world.queue_free()
	await process_frame
	await process_frame
	print("Balance fixes checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
