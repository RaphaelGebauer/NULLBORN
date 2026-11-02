extends SceneTree
var passes: int=0
var failures: int=0
var model: RefCounted
var world: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok:
		passes+=1
		print("PASS ",text)
	else:
		failures+=1
		push_error("FAIL "+text)
func clear() -> void:
	world.enemies.clear()
	world.enemy_pool.clear()
	world.shots.clear()
	world.hazards.clear()
	world.pickups.clear()
	world.player.position=Vector2.ZERO
	world.player.invulnerable=0
	model.hp=model.max_hp
	model.instability=0
func ordinary() -> Dictionary:
	var kinds: Array=model.registry.get_def("wave_%02d"%mini(29,int(model.time/60))).values.weights.keys()
	return world.spawn_enemy(kinds[0],Vector2(300,0))
func elite(id: String) -> Dictionary:
	clear()
	model.time=900
	var e: Dictionary=ordinary()
	check(world.elite_director.promote(e,[id]),"Promote "+id)
	return e
func run() -> void:
	model=load("res://scripts/run_model.gd").new()
	model.crit=0
	world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	model.weapons={}
	check(model.registry.affix_definitions.size()==7 and model.registry.errors.is_empty(),"Seven validated affix definitions")
	var normal=load("res://scripts/run_model.gd").new()
	var quick=load("res://scripts/run_model.gd").new()
	quick.fast=true
	normal.tick(20)
	quick.tick(10)
	check(is_equal_approx(normal.instability,quick.instability) and normal.time==quick.time,"Quick Mode shares run clock and instability")
	for band in range(5):
		model.instability=model.rift_state.THRESHOLDS[band]
		check(model.rift_state.band()==band and model.rift_state.modifiers()==model.rift_state.MODIFIERS[band],"Exact factors band "+str(band))
	model.instability=-20
	check(model.instability==0 and model.rift_state.band()==0,"Backwards band and lower clamp")
	model.instability=120
	check(model.instability==100 and model.rift_state.peak==100,"Upper clamp and persistent peak")
	var warnings: Array=[]
	model.instability_warning.connect(func():warnings.append(true))
	model.instability_warning_shown=false
	model.instability=75
	model.instability=74
	model.instability=90
	check(warnings.size()==1,"Unstable warning cannot repeat with threshold flutter")
	clear()
	model.time=0
	world.rifts.update()
	check(world.rifts.node.is_empty(),"No early rift")
	for slot in range(4):
		model.time=world.rifts.SCHEDULE[slot]
		world.rifts.update()
		check(not world.rifts.node.is_empty() and world.rifts.node.slot==slot+1,"Rift schedule "+str(slot+1))
		check(not world.rifts.interact(),"Rift requires proximity")
		world.player.position=world.rifts.node.pos
		check(world.rifts.interact() and not world.rifts.interact(),"Rift interaction queues once")
		model.instability=40
		model.hp=model.max_hp*.5
		model.xp=0
		var gold: int=model.gold
		var need: float=model.required_xp()
		var over: bool=slot%2==1
		check(world.rifts.choose(over) and not world.rifts.choose(over),"Rift choice is single-use")
		if over:
			check(model.instability==60 and model.gold-gold==roundi(120*(1+model.time/1800)) and is_equal_approx(model.xp,need*.35),"Overcharge gold and unscaled XP")
		else: check(model.instability==20 and is_equal_approx(model.hp,model.max_hp*.6),"Stabilize reduces and heals actual HP")
	check(model.rifts_stabilized==2 and model.rifts_overcharged==2 and world.rifts.slots_used==4,"Four choices and truthful counters")
	world.rifts.slots_used=0
	model.time=360
	world.rifts.update()
	model.time=450
	world.rifts.update()
	check(world.rifts.node.is_empty(),"Rift expires at 90 run seconds")
	clear()
	model.time=299
	check(not world.elite_director.promote(ordinary(),["swift"]),"No elite before minute five")
	model.time=900
	var child: Dictionary=world.spawn_enemy("mite",Vector2(100,0),true)
	var boss: Dictionary=world.spawn_enemy("astral_guardian",Vector2(300,0))
	check(not world.elite_director.promote(child,["swift"]) and not world.elite_director.promote(boss,["swift"]),"No elite bosses or children")
	check(not world.elite_director.promote(world.spawn_enemy("splitter",Vector2(400,0)),["swift"]),"Splitters cannot become elites")
	var e: Dictionary=ordinary()
	check(not world.elite_director.promote(e,["swift","swift"]) and not world.elite_director.promote(e,["vampiric","regenerating"]),"Unique affixes and no endless healing combination")
	clear()
	for i in range(2): check(world.elite_director.promote(ordinary(),["swift"]),"Two-elite capacity "+str(i))
	check(not world.elite_director.promote(ordinary(),["swift"]),"Dormant cap two")
	model.instability=75
	check(world.elite_director.promote(ordinary(),["swift"]) and not world.elite_director.promote(ordinary(),["swift"]),"Unstable cap three")
	e=elite("armored")
	var hp: float=e.hp
	world.hit(e,100,{},"test",true)
	check(hp-e.hp==80,"Armored reduces actual damage once")
	e=elite("swift")
	var base: Dictionary=world.spawn_enemy(e.kind,Vector2(400,0))
	check(is_equal_approx(e.speed,minf(300,base.speed*1.06*1.18)) and is_equal_approx(e.max_hp,base.max_hp*2.5) and e.xp==base.xp*2,"Swift and base elite scaling")
	e=elite("regenerating")
	e.hp=e.max_hp*.5
	hp=e.hp
	world.elite_director.update(e,1)
	check(is_equal_approx(e.hp-hp,e.max_hp*.0035),"Regenerating actual healing")
	world.hit(e,1,{},"ash_bow",true)
	hp=e.hp
	e.age=2.9
	world.elite_director.update(e,1)
	check(e.hp==hp,"Fire suppresses regeneration for three seconds")
	e.age=3.01
	world.elite_director.update(e,1)
	check(e.hp>hp,"Regeneration resumes after fire lock")
	e=elite("vampiric")
	e.hp=e.max_hp*.5
	hp=e.hp
	world.elite_director.contact(e,false)
	check(e.hp==hp,"Vampiric ignores i-frame/non-hits")
	world.elite_director.contact(e,true)
	world.elite_director.contact(e,true)
	check(is_equal_approx(e.hp,hp+e.max_hp*.05),"Vampiric heals once during cooldown")
	e.age=3
	world.elite_director.contact(e,true)
	check(is_equal_approx(e.hp,hp+e.max_hp*.1),"Vampiric three-second cooldown")
	e=elite("blinking")
	var origin: Vector2=e.pos
	world.elite_director.update(e,7)
	check(e.pos==origin and is_equal_approx(e.elite_state.warning,.3),"Blink announces destination for 0.3 seconds")
	world.elite_director.update(e,.29)
	check(e.pos==origin,"Blink cannot teleport early")
	world.elite_director.update(e,.011)
	check(e.pos.distance_to(origin)>=100 and e.pos.distance_to(origin)<=150 and e.pos.distance_to(world.player.position)>90,"Blink safe side displacement")
	e=elite("hexbound")
	world.elite_director.update(e,5.99)
	check(world.shots.is_empty(),"Hexbound waits six seconds")
	world.elite_director.update(e,.02)
	check(world.shots.size()==1 and world.shots[0].hostile and is_equal_approx(world.shots[0].velocity.length(),115),"Hexbound real slow hostile shot")
	while world.shots.size()<650: world.projectile(Vector2.ZERO,Vector2.RIGHT,{},"cap")
	world.elite_director.update(e,6)
	check(world.shots.size()==650,"Hexbound honors projectile cap")
	e=elite("volatile")
	world.player.position=e.pos
	var kills: int=model.elite_kills
	e.hp=0
	world.kill_enemy(e)
	world.kill_enemy(e)
	check(model.elite_kills==kills+1 and model.instability==.5 and world.hazards.size()==1,"Elite death and volatility booked once")
	check(world.pickups.any(func(p):return p.kind=="gold" and p.value==45) and not world.pickups.any(func(p):return p.kind=="chest"),"Elite gold and no evolution chest")
	var reused: Dictionary=world.spawn_enemy("wisp",Vector2(500,0))
	check(not reused.elite and reused.affixes.is_empty() and reused.boss_hp_phase==1 and reused.phase_transitions==0,"Pooled enemy resets all E3 state")
	world.kill_enemy(reused)
	check(world.hazards.size()==1,"Pool reuse cannot repeat volatile explosion")
	hp=model.hp
	world.update_hazards(.74)
	check(model.hp==hp,"Volatile warning causes no early damage")
	world.update_hazards(.02)
	check(model.hp<hp and world.hazards[0].fired,"Volatile explodes after warning")
	for kind in ["astral_guardian","void_queen","storm_core"]:
		clear()
		model.time=1200
		e=world.spawn_enemy(kind,Vector2(300,0))
		e.hp=e.max_hp*.5
		var before: Vector2=e.pos
		world.update_enemy(e,.1)
		check(e.boss_hp_phase==2 and e.phase_transitions==1 and e.pos==before and e.transition_left>0,"Boss half-HP transition immobilizes "+kind)
		world.update_enemy(e,.49)
		check(world.shots.is_empty() and world.hazards.is_empty(),"No attack during transition "+kind)
		for i in range(10): world.update_enemy(e,.1)
		check(e.phase_transitions==1 and e.phase==0,"HP phase separate from attack step "+kind)
		e.hp=0
		world.kill_enemy(e)
		check(world.pickups.any(func(p):return p.kind=="chest" and p.eligible),"Boss spawn-time chest preserved "+kind)
	clear()
	e=world.spawn_enemy("astral_guardian",Vector2(300,0))
	e.boss_timers.dash=0
	var v: Vector2=world.bosses.update(e,Vector2.LEFT,0)
	check(v==Vector2.ZERO and e.dash_state==1 and e.dash_left==.8,"Guardian telegraphed dash")
	v=world.bosses.update(e,Vector2.UP,.79)
	check(v==Vector2.ZERO,"Guardian waits whole dash warning")
	world.bosses.update(e,Vector2.UP,.02)
	v=world.bosses.update(e,Vector2.UP,.01)
	check(v==Vector2.LEFT*240,"Guardian fixed direction and 240 speed")
	world.bosses.update(e,Vector2.UP,.7)
	check(e.dash_state==0,"Guardian dash bounded to 0.7 seconds")
	e.hp=e.max_hp*.5
	world.bosses.update(e,Vector2.LEFT,.6)
	e.boss_timers.dash=4
	e.boss_timers.stars=0
	e.boss_recovery=0
	world.bosses.update(e,Vector2.LEFT,.01)
	check(world.hazards.size()==3 and world.hazards.all(func(h):return h.radius==65 and h.delay==1 and h.pos.distance_to(world.player.position)>h.radius+13),"Guardian three starfalls leave center corridor")
	clear()
	e=world.spawn_enemy("void_queen",Vector2(300,0))
	for i in range(10): world.bosses.safe_summons(e)
	check(world.enemies.filter(func(x):return x.parent_boss==e.id).size()==6 and world.enemies.all(func(x):return not x.child or x.pos.distance_to(world.player.position)>90),"Queen cap six safe children")
	e.boss_timers.bolts=0
	world.bosses.update(e,Vector2.LEFT,.01)
	check(world.shots.size()==2 and world.shots.all(func(s):return s.values.has("curve") and s.delay==.5),"Queen two curved warned bolts")
	e.boss_hp_phase=2
	for i in range(4):
		e.boss_timers.zones=0
		e.boss_recovery=0
		world.bosses.update(e,Vector2.LEFT,0)
	check(world.hazards.size()==4 and world.hazards.all(func(h):return h.radius==75 and h.delay==1 and h.life==3.5),"Queen maximum four 1+2.5-second zones")
	world.player.position=world.hazards[0].pos
	hp=model.hp
	world.update_hazards(.99)
	check(model.hp==hp and world.player.slow_left==0,"Null zone telegraph harmless")
	world.update_hazards(.02)
	hp=model.hp
	check(world.player.slow_left==1,"Null zone real nonstacking slow")
	world.player.invulnerable=0
	world.update_hazards(.7)
	check(model.hp==hp,"Null zone damage interval at least 0.8 seconds")
	clear()
	e=world.spawn_enemy("storm_core",Vector2(300,0))
	for phase in [1,2]:
		world.shots.clear()
		e.boss_hp_phase=phase
		e.attack_pattern_step=0
		e.boss_timers.storm=0
		e.boss_recovery=0
		world.bosses.update(e,Vector2.LEFT,0)
		check(e.safe_gap_degrees>=(50 if phase==1 else 60) and world.shots.all(func(s):return absf(wrapf(s.velocity.angle()-e.safe_gap_angle,-PI,PI))>=deg_to_rad(e.safe_gap_degrees)*.5 and s.delay==.8),"Storm radial safe gap phase "+str(phase))
	world.shots.clear()
	e.boss_timers.storm=0
	e.boss_recovery=0
	world.hazards.clear()
	world.bosses.update(e,Vector2.LEFT,0)
	check(world.hazards.size()==3 and world.hazards.all(func(h):return h.delay==1 and h.has("end")) and world.shots.is_empty(),"Storm alternates three warned beams")
	while world.hazards.size()<100: world.hazard(Vector2.ZERO,10,1,1)
	e.boss_recovery=0
	e.boss_timers.storm=0
	world.bosses.update(e,Vector2.LEFT,0)
	check(world.hazards.size()==100,"Boss hazards obey global cap")
	world.queue_free()
	await process_frame
	await process_frame
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.set_process(false)
	app.save.persistent=false
	app.start_run()
	app.events=["MUTATION:arcane_needle","LEVELUP","CHEST"]
	app.queue_run_event("RIFT")
	check(app.events==["MUTATION:arcane_needle","RIFT","LEVELUP","CHEST"],"Rift follows mutation and preserves pending FIFO")
	app.model.time=360
	app.world.rifts.update()
	app.world.player.position=app.world.rifts.node.pos
	app.world.rifts.interact()
	app.events=["RIFT"]
	app.show_event()
	check(app.state=="RIFT" and paused,"Rift choice genuinely pauses simulation")
	var time: float=app.model.time
	await process_frame
	check(app.model.time==time,"No clock advance during choice")
	app.choose_rift(false)
	check(app.state=="RUNNING" and not paused and app.model.rifts_stabilized==1,"Choice resumes exactly once")
	app.queue_free()
	await process_frame
	await process_frame
	print("Rift checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
