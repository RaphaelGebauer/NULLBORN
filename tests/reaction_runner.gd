extends SceneTree
var passes: int=0
var failures: int=0
var world: Node2D
var model: RefCounted
const SOURCES: Dictionary={"frost":"frost_shard","storm":"lightning_call","fire":"ash_bow","toxin":"thorn_halo","void":"soul_well"}
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok:
		passes+=1
		print("PASS ",text)
	else:
		failures+=1
		push_error("FAIL "+text)
func reset() -> void:
	world.enemies.clear()
	world.enemy_pool.clear()
	world.shots.clear()
	world.texts.clear()
	world.combat.elapsed=0
	world.reactions.events_total=0
	world.reactions.budget_second=-1
	world.reactions.events_this_second=0
	world.reactions.counts.clear()
	world.reactions.visuals.clear()
	model.statistics=load("res://scripts/run_statistics.gd").new()
	model.crit=0
	model.passives={}
	model.weapon_mutations={}
	model.runes=[]
func enemy(pos: Vector2=Vector2(100,0),boss: bool=false) -> Dictionary:
	var e: Dictionary=world.spawn_enemy("astral_guardian" if boss else "guardian",pos)
	e.hp=10000
	e.max_hp=10000
	return e
func damage() -> float: return model.statistics.damage_by_source.get(world.reactions.SOURCE,0)
func run() -> void:
	model=load("res://scripts/run_model.gd").new()
	world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	check(model.registry.errors.is_empty() and model.registry.reaction_definitions.size()==4,"Four validated reaction definitions")
	for d in world.reactions.DEFINITIONS:
		for reverse in [false,true]:
			reset()
			var e: Dictionary=enemy()
			var second: Dictionary=enemy(Vector2(125,0))
			var far: Dictionary=enemy(Vector2(800,0))
			world.grid.rebuild(world.enemies)
			var first: String=d.elements[1 if reverse else 0]
			var last: String=d.elements[0 if reverse else 1]
			world.hit(e,100,{},SOURCES[first])
			check(world.reactions.events_total==0,"First tag cannot react "+d.id+str(reverse))
			world.combat.elapsed=.1
			var hp: float=e.hp
			world.hit(e,100,{},SOURCES[last])
			check(world.reactions.events_total==1 and world.reactions.counts.get(d.id,0)==1,"Bidirectional reaction "+d.id+str(reverse))
			check(is_equal_approx(hp-e.hp,100+100*d.bonus),"Actual primary bonus "+d.id+str(reverse))
			check(is_equal_approx(10000-second.hp,100*d.secondary) and far.hp==10000,"Bounded secondary reach "+d.id+str(reverse))
			check(second.element_history.is_empty(),"Secondary proc cannot apply reaction elements "+d.id+str(reverse))
			check(is_equal_approx(damage(),100*(d.bonus+d.secondary)),"Separate attributed reaction damage "+d.id+str(reverse))
			if d.id=="void_shatter": check(e.statuses.slow==.75,"Void Shatter actual 0.75-second slow")
			if d.id=="blightburst": check(e.statuses.has("burn") and second.statuses.has("burn"),"Blightburst applies light burn")
			world.hit(e,100,{},SOURCES[first])
			check(world.reactions.events_total==1,"Shared target cooldown "+d.id+str(reverse))
			check(model.statistics.critical_hits==0,"Reaction never rolls crit "+d.id+str(reverse))
			var total: float=0
			for value in model.statistics.damage_by_source.values(): total+=value
			check(is_equal_approx(total,model.statistics.total_damage),"No damage double-accounting "+d.id+str(reverse))
	# Exact window/cooldown edges on fresh targets, not global wall time.
	for gap in [2.99,3.0,3.001]:
		reset()
		var e: Dictionary=enemy()
		world.hit(e,100,{},"moon_blade")
		world.combat.elapsed=gap
		world.hit(e,100,{},"spark_orbit")
		check(world.reactions.events_total==(1 if gap<=3 else 0),"Three-second window edge "+str(gap))
	reset()
	var e: Dictionary=enemy()
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"lightning_call")
	world.combat.elapsed=1.49
	world.hit(e,100,{},"moon_blade")
	check(world.reactions.events_total==1,"Cooldown not ready at 1.49")
	world.combat.elapsed=1.5
	world.hit(e,100,{},"lightning_call")
	check(world.reactions.events_total==2,"Cooldown ready exactly at 1.5")
	reset()
	e=enemy()
	world.hit(e,100,{},"arcane_needle")
	world.hit(e,100,{},"prism_disc")
	check(e.element_history.is_empty() and world.reactions.events_total==0,"Neutral attacks do not create tags")
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"moon_blade")
	check(world.reactions.events_total==0 and e.element_history.size()==1,"Same element on two weapons cannot self-react")
	reset()
	e=enemy()
	world.hit(e,100,{},"dusk_storm")
	check(e.element_history.size()==2 and world.reactions.events_total==0,"Fusion applies union without first-hit self-reaction")
	world.hit(e,100,{},"lightning_call")
	check(world.reactions.counts.get("arc_freeze",0)==1,"Fusion inherited frost really reacts")
	reset()
	e=enemy()
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"soul_well")
	world.combat.elapsed=1.6
	world.hit(e,100,{},"lightning_call")
	check(world.reactions.counts.get("arc_freeze",0)==1 and world.reactions.counts.get("rift_conduction",0)==0,"Fixed table priority when multiple pairs match")
	for d in world.reactions.DEFINITIONS:
		reset()
		e=enemy(Vector2(100,0),true)
		var secondary: Dictionary=enemy(Vector2(120,0),true)
		world.grid.rebuild(world.enemies)
		world.hit(e,200,{},SOURCES[d.elements[0]])
		world.hit(e,200,{},SOURCES[d.elements[1]])
		check(is_equal_approx(damage(),100*(d.bonus+d.secondary)),"Boss bonus damage halved "+d.id)
		if d.id=="void_shatter": check(e.statuses.slow==.35,"Boss Void Shatter slow 0.35 seconds")
	reset()
	for i in range(50):
		e=enemy(Vector2(100+i*300,0))
		world.hit(e,100,{},"frost_shard")
		world.hit(e,100,{},"soul_well")
	check(world.reactions.events_total==40 and world.reactions.events_this_second==40,"Global 40-event cap for fifty targets")
	check(world.reactions.visuals.size()==6,"At most six subtle reaction labels")
	world.combat.elapsed=1
	e=enemy(Vector2(0,500))
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"soul_well")
	check(world.reactions.events_total==41,"Global budget replenishes next combat second")
	world.reactions.update(.5)
	check(world.reactions.visuals.is_empty(),"Reaction visuals expire without retained enemy references")
	reset()
	e=enemy()
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"lightning_call",true)
	check(world.reactions.events_total==0 and not e.element_history.has("storm"),"Proc damage neither applies tags nor triggers reaction")
	# The triggering hit includes crit, execution and armor once; the bonus bypasses them.
	reset()
	model.time=900
	e=enemy()
	world.elite_director.promote(e,["armored"])
	e.hp=e.max_hp*.3
	world.hit(e,100,{},"frost_shard")
	model.passives={"execution_seal":5}
	model.crit=1
	world.hit(e,100,{},"soul_well")
	var final: float=round(100*1.4*model.crit_factor*.8)
	check(damage()==round(final*.5) and model.statistics.critical_hits==1,"Final crit/execute/armor hit used once for reaction")
	reset()
	e=enemy()
	world.hit(e,100,{},"frost_shard")
	e.hp=5
	e.statuses.death_fire=3
	world.hit(e,1,{},"soul_well")
	# Use a separate overkill via the real reaction source and proc path.
	world.reactions.reaction_hit(e,100,"void_shatter","soul_well")
	check(e.hp<=0 and e.no_death_proc and e.leech_source=="","Reaction kill blocks explosion/lifesteal cascade")
	world.kill_enemy(e)
	var reused: Dictionary=world.spawn_enemy("guardian",Vector2.ZERO)
	check(reused.element_history.is_empty() and reused.reaction_ready_at==0 and reused.dot_sources.is_empty(),"Pool reuse clears history, cooldown and DoT ownership")
	reset()
	e=enemy()
	world.hit(e,100,{},"ash_bow")
	world.hit(e,100,{},"thorn_halo")
	var before: float=damage()
	world.hit_dot(e,"burn",4)
	check(damage()==before+4 and world.reactions.events_total==1,"Reaction burn remains attributed and cannot re-enter")
	reset()
	e=enemy()
	for i in range(12): enemy(Vector2(110+i,0))
	world.grid.rebuild(world.enemies)
	world.hit(e,100,{},"ash_bow")
	world.hit(e,100,{},"thorn_halo")
	check(world.enemies.filter(func(target):return target.statuses.has("burn")).size()==8 and damage()==8*45,"Blightburst cap eight including primary")
	reset()
	e=enemy()
	for i in range(5): enemy(Vector2(110+i,0))
	world.grid.rebuild(world.enemies)
	world.hit(e,100,{},"lightning_call")
	world.hit(e,100,{},"soul_well")
	check(world.enemies.filter(func(target):return target.hp<10000).size()==3 and damage()==50,"Rift Conduction hits only two additional targets")
	# Real mutation hook returns only elements which that hit actually applied.
	reset()
	e=enemy()
	model.weapons={"storm_bomb":4}
	model.ensure_mutations()
	var charged: Resource=null
	for d in model.registry.mutation_choices("storm_bomb"):
		if d.values.effect=="charged": charged=d
	check(charged!=null and model.select_mutation("storm_bomb",charged.id),"Select actual Charged Air mutation")
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"storm_bomb")
	check(e.statuses.has("charged") and world.reactions.counts.get("arc_freeze",0)==1,"Charged Air participates without recursive mutation procs")

	reset()
	model.time=900
	e=enemy()
	world.elite_director.promote(e,["regenerating"])
	world.hit(e,1,{"burn":1},"prism_disc")
	e.age=2
	world.hit(e,1,{},"prism_disc")
	check(e.elite_state.fire_until==3,"Unrelated hits cannot extend fire regeneration lock")
	world.hit_dot(e,"burn",4)
	check(e.elite_state.fire_until==5,"Actual fire DoT extends regeneration lock")

	reset()
	e=enemy()
	var edge: Dictionary=enemy(Vector2(220,0))
	var outside: Dictionary=enemy(Vector2(221,0))
	world.grid.rebuild(world.enemies)
	world.hit(e,100,{},"frost_shard")
	world.hit(e,100,{},"lightning_call")
	check(edge.hp==9970 and outside.hp==10000,"Arc Freeze exact 120-pixel chain radius ignores expanded broadphase")
	reset()
	e=enemy()
	model.weapons={"arcane_needle":4}
	model.ensure_mutations()
	for d in model.registry.mutation_choices("arcane_needle"):
		if d.values.effect=="primary": model.select_mutation("arcane_needle",d.id)
	world.hit(e,100,{"burn":1},"prism_disc")
	world.hit(e,100,{"poison":1},"arcane_needle")
	check(world.reactions.counts.get("blightburst",0)==1,"Only actually applied status tags enable a neutral weapon reaction")

	reset()
	e=enemy()
	world.hit(e,100,{"burn":1},"ash_bow")
	world.combat.elapsed=2.9
	world.hit(e,100,{},"prism_disc")
	check(e.element_history.fire.time==0 and e.element_history.fire.source=="ash_bow","Unrelated hits never refresh another weapon's element timestamp")
	world.combat.elapsed=3.1
	world.hit(e,100,{},"thorn_halo")
	check(world.reactions.events_total==0,"A persistent old burn cannot fake a recent fire hit")
	world.queue_free()
	await process_frame
	await process_frame
	print("Reaction checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
