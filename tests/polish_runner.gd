extends SceneTree
const Model=preload("res://scripts/run_model.gd")
const Report=preload("res://scripts/run_report.gd")
var passes: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok:
		passes+=1
		print("PASS ",text)
	else:
		failures+=1
		push_error("FAIL "+text)
func labels(node: Node) -> String:
	var result: String=node.text+"\n" if node is Label else ""
	for child in node.get_children(): result+=labels(child)
	return result
func run() -> void:
	var model=Model.new()
	model.crit=1
	model.recalculate()
	model.crit=1
	var world=load("res://scenes/game.tscn").instantiate()
	world.model=model
	root.add_child(world)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var e: Dictionary=world.spawn_enemy("guardian",Vector2(100,0))
	e.hp=10
	world.hit(e,100,{},"arcane_needle")
	check(model.statistics.total_damage==10 and model.statistics.highest_critical_hit==10 and model.statistics.critical_hits==1,"Real critical overkill counts actual ten HP only")
	check(world.texts[0].critical and world.texts[0].text.ends_with("!") and e.flash<=.06,"Critical number identity and micro hitflash")
	e=world.spawn_enemy("guardian",Vector2(200,0))
	e.hp=10000
	model.crit=0
	world.hit(e,20,{},"star_piercer")
	world.hit(e,5,{"reaction":true},"Elemental Reactions",true)
	check(model.statistics.damage_by_source.arcane_needle==10 and model.statistics.damage_by_source.star_piercer==20 and model.statistics.total_damage==35,"Base, evolution and reactions stay separate")
	model.tick(2)
	var rows: Array=Report.damage_rows(model)
	check(rows[0].id=="star_piercer" and rows[0].dps==10,"Sorted source rows use actual combat duration")
	var share: float=0
	var sum: float=0
	for row in rows:
		share+=row.share
		sum+=row.damage
	check(is_equal_approx(share,100) and sum==model.statistics.total_damage,"Damage table reconciles to measured total")
	var quick=Model.new()
	quick.fast=true
	quick.tick(2)
	quick.statistics.record_damage("arcane_needle",20,100,false,quick.statistics.combat_seconds)
	check(quick.time==4 and Report.damage_rows(quick)[0].dps==10,"Quick Mode DPS uses active combat seconds")

	var hero_model=Model.new()
	hero_model.hero="brann"
	hero_model.recalculate()
	check(str(Report.build_sections(hero_model)).contains("+1.00 armor"),"Build reports flat character armor without inventing a percentage")
	hero_model.hero="noctis"
	hero_model.recalculate()
	check(str(Report.build_sections(hero_model)).contains("+0.15 critical multiplier"),"Build reports additive critical multiplier correctly")
	var stats=load("res://scripts/run_statistics.gd").new()
	for second in range(100): stats.record_damage("test",10,10,false,second)
	check(stats.bucket_seconds.size()==11 and stats.highest_ten_second_dps==10,"Peak ten-second DPS uses fixed eleven buckets")
	var xp: float=model.statistics.xp_gained
	model.add_xp(1)
	model.add_xp(1,false)
	check(is_equal_approx(model.statistics.xp_gained-xp,model.growth+1),"Actual XP counters apply Growth exactly once")
	world.drop(world.player.position,7,"gold")
	var pickup: Dictionary=world.pickups[-1]
	world.collect(pickup)
	world.collect(pickup)
	check(model.statistics.gold_from_pickups==7 and model.gold==7,"Gold collected and counted exactly once")
	model.hp=90
	model.heal(100)
	check(model.statistics.total_healing==10,"Healing records no overheal")
	var upgrades: int=model.statistics.upgrades
	model.upgrade("not_an_upgrade")
	model.upgrade("reward_gold")
	check(model.statistics.upgrades==upgrades+1,"Only accepted upgrades count")
	model.weapons={"arcane_needle":3}
	model.passives={"power_core":5}
	model.upgrade("arcane_needle")
	model.select_mutation("arcane_needle",model.registry.mutation_choices("arcane_needle")[0].id)
	model.upgrade("arcane_needle")
	model.evolution(true)
	check(model.statistics.mutations==1 and model.statistics.evolutions==1 and model.statistics.fusions==0,"Mutation/evolution measured on successful actions")
	model.weapons={"ash_bow":5,"frost_shard":5}
	model.passives={"runner_boots":5}
	model.evolution(true)
	check(model.statistics.fusions==1 and model.statistics.evolutions==1,"Fusion event counted separately exactly once")
	world.reduce_flash=true
	world.hit(e,1,{},"prism_disc")
	check(e.flash==0,"Reduce Flashes suppresses enemy hitflash")
	world.damage_texts=false
	var count: int=world.texts.size()
	world.hit(e,1,{},"prism_disc")
	check(world.texts.size()==count,"Damage Numbers setting suppresses new text")
	world.damage_texts=true
	for i in range(150): world.hit(e,1,{},"prism_disc")
	check(world.texts.size()==70,"Text cap remains seventy")
	world.reduce_flash=false
	world.player.invulnerable=0
	world.hurt_player(2)
	check(world.shake==0 and world.player.hit_flash<=.07,"Normal incoming hit never shakes camera")
	world.player.invulnerable=0
	world.hurt_player(20,true)
	check(world.shake<=.07 and world.shake_amplitude<=1.5,"Strong boss hit bounded to 1.5 pixels and 0.07 seconds")
	var valid: bool=true
	for i in range(10):
		world.update_feedback(.01)
		valid=valid and world.player.get_node("Camera2D").offset.length()<=1.5
	check(valid and world.player.get_node("Camera2D").offset==Vector2.ZERO,"Boss-hit camera decays smoothly to zero")
	world.request_shake(2,.1)
	world.screen_shake=false
	world.update_feedback(.01)
	check(world.player.get_node("Camera2D").offset==Vector2.ZERO,"Screen Shake off means exactly zero camera offset")
	world.screen_shake=true
	world.shake=0
	var boss: Dictionary=world.spawn_enemy("astral_guardian",Vector2(500,0))
	boss.hp=0
	world.kill_enemy(boss)
	valid=world.shake<=.1 and world.shake_amplitude<=2
	for i in range(12):
		world.update_feedback(.01)
		valid=valid and world.player.get_node("Camera2D").offset.length()<=2
	check(valid and world.player.get_node("Camera2D").offset==Vector2.ZERO,"Boss-death shake bounded to two pixels for 0.1 seconds")
	model.constellation_nodes=["last_star"]
	model.last_star_used=false
	model.hp=26
	world.player.invulnerable=0
	check(world.hurt_player(5) and model.hp>26,"Successful damage remains a real hit when Last Star heals above previous HP")

	model.weapons={"blood_thorns":1}
	model.crit=1
	world.player.invulnerable=0
	model.hp=model.max_hp
	var reflected: Dictionary=world.spawn_enemy("guardian",world.player.position+Vector2(50,0))
	reflected.hp=1000
	world.grid.rebuild(world.enemies)
	var reflected_before: float=model.statistics.damage_by_source.get("blood_thorns",0)
	world.hurt_player(1)
	check(model.statistics.damage_by_source.get("blood_thorns",0)-reflected_before==round(20*.93),"Blood Thorns reflection keeps weapon attribution without secondary crit/mutation rerolls")
	world.queue_free()
	await process_frame
	await process_frame
	var app=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(app)
	app.save.persistent=false
	app.start_run()
	app.choose_rune(0)
	app.world.set_physics_process(false)
	app.world.player.set_physics_process(false)
	app.model.weapons={"arcane_needle":5}
	app.model.passives={"power_core":5}
	app.save.data.evolved_recipes=[]
	app.save.data.seen=[]
	app.model.ensure_mutations()
	app.model.select_mutation("arcane_needle",app.catalog.mutation_choices("arcane_needle")[0].id)
	app.events=[]
	app.build_details()
	var text: String=labels(app.panel)
	check(app.state=="BUILD" and paused and text.contains("Empty weapon slot") and text.contains("Current Stats"),"Build displays six slots and actual stats while paused")
	check(not text.contains("Star Piercer") and text.contains("Undiscovered:"),"Build Details cannot leak secret result or catalyst recipe")
	var before: Array=[app.model.time,app.model.xp,app.model.level,app.model.rng.state]
	await process_frame
	app.build_details()
	check(before==[app.model.time,app.model.xp,app.model.level,app.model.rng.state],"Repeated build inspection neither ticks nor rolls nor grants XP")
	app.save.mark_evolved("star_piercer")
	app.build_details()
	check(labels(app.panel).contains("Star Piercer") and labels(app.panel).contains("Power Core Lv5 · ready"),"Actually discovered recipe visible")
	check(app.detail_actions.get_child_count()==2 and app.detail_scroll.offset_bottom==-90,"Build actions live outside scrolling content")
	var cancel:=InputEventAction.new()
	cancel.action="ui_cancel"
	cancel.pressed=true
	app._unhandled_input(cancel)
	check(app.state=="PAUSED" and paused,"Back from Build returns to Pause without simulation")
	app.build_details()
	app.detail_actions.get_child(1).pressed.emit()
	check(app.state=="RUNNING" and not paused,"Build Resume action works")
	app.model.kills=100
	app.check_unlocks()
	check("first_100" in app.model.unlocked_this_run,"Mid-run achievements retained for final report")
	app.model.time=1800
	app.model.bosses=3
	app.model.instability=80
	app.model.finished=true
	app.result(true)
	var gold: int=app.save.data.total_gold
	var stars: int=app.save.data.starlight
	app.result(true)
	check(app.save.data.total_gold==gold and app.save.data.starlight==stars and stars==8 and "first_100" in app.model.unlocked_this_run,"Repeated result render cannot double-bank gold or stars")
	text=labels(app.panel)
	check(text.contains("Total Damage Dealt") and text.contains("Damage by Source") and text.contains("Highest Critical Hit") and text.contains("Starlight +8"),"Result presents measured stats and real reward")
	check(app.detail_actions.get_child(0).text=="Try Again" and app.detail_actions.get_child(1).text=="Main Menu","Result actions always reachable outside scroll")
	app.detail_actions.get_child(0).pressed.emit()
	check(app.state=="RUNE" and not app.model.finished,"Try Again starts a fresh real run")
	app.choose_rune(0)
	app.model.hurt(99999)
	check(app.state=="DEFEAT" and app.model.finished,"Real fatal damage reaches defeat result")

	app.menu()
	app.start_run()
	app.choose_rune(0)
	app.save.persistent=true
	app.save.path="user://missing-polish-save-directory/save.json"
	app.model.finish(false)
	check(not app.model.banked and labels(app.panel).contains("Pending Gold") and app.detail_actions.get_child(0).text=="Retry Saving","Storage failure labels pending rewards and exposes fixed controller-accessible retry")
	app.save.persistent=false
	app.detail_actions.get_child(0).pressed.emit()
	check(app.model.banked and labels(app.panel).contains("Banked Gold") and app.detail_actions.get_child_count()==2,"Result retry saves once and restores normal fixed actions")
	app.menu()
	app.queue_free()
	await process_frame
	await process_frame
	print("Polish checks: ",passes," PASS / ",failures," FAIL")
	quit(0 if failures==0 else 1)
