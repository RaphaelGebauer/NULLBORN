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
	check(scene.model.kills>=1,"Echtes automatisches Projektil tötet Gegner")
	var registry=model.registry
	check(registry.errors.is_empty(),"Registry validiert Ressourcen und Abhängigkeiten")
	for pair in [["weapon",12],["passive",13],["enemy",15],["character",4],["wave",30],["evolution",14],["rune",8],["stage",2]]:
		check(registry.catalogs[pair[0]].size()==pair[1],"Katalog "+pair[0])
	for weapon in registry.catalogs.weapon:
		check(registry.get_def(weapon).upgrades.size()==7 and registry.weapon_values(weapon,8).damage>=registry.weapon_values(weapon,1).damage,"Sieben echte Upgrades: "+weapon)
	model.weapons={"arcane_needle":8,"ash_bow":8,"spark_orbit":8,"thorn_halo":8,"lightning_call":8,"moon_blade":8}
	model.passives={"power_core":5,"clockwork":5,"runner_boots":5,"focus_lens":5,"multiplicity":5,"lasting_seal":5}
	check(model.legal().is_empty(),"6+6 voll und maximal: keine illegalen Angebote")
	check(model.offers()==["reward_gold","reward_heal","reward_xp"],"Drei verschiedene Fallbacks")
	model.weapons={"arcane_needle":1}
	model.passives={}
	var rr: int=model.rerolls
	check(model.reroll().size()==3 and model.rerolls==rr-1,"Reroll verbraucht Charge")
	check(model.banish("power_core").size()==3 and not "power_core" in model.legal() and model.banishes==0,"Banish schließt Item aus")
	check(model.skip() and model.skips==0,"Skip mit XP und Charge")
	model.passives={"blood_vial":5,"power_core":5,"multiplicity":5,"clockwork":5}
	model.recalculate()
	check(model.max_hp==175 and model.might==1.5 and model.amount==2 and is_equal_approx(model.projectile_damage,1.15),"Passivwerte deterministisch")
	model.recalculate()
	check(model.max_hp==175,"Keine multiplikative Stat-Drift")
	var combat_world=scene.world
	for behavior in ["needle","aura","orbit","beam","bomb"]:
		combat_world.enemies.clear()
		combat_world.shots.clear()
		combat_world.combat.effects.clear()
		var target: Dictionary=combat_world.spawn_enemy("guardian",Vector2(60,0))
		target.hp=10000
		target.max_hp=10000
		target.speed=0
		combat_world.grid.rebuild(combat_world.enemies)
		var weapon: String={"needle":"arcane_needle","aura":"thorn_halo","orbit":"spark_orbit","beam":"sun_beam","bomb":"storm_bomb"}[behavior]
		var values: Dictionary=registry.weapon_values(weapon,1)
		if behavior=="orbit":
			combat_world.combat.elapsed=0
			combat_world.combat.orbit(weapon,values,.016)
		else:
			combat_world.combat.call("attack_"+behavior,weapon,values,target)
			for i in range(80):
				combat_world.combat.update(.016)
				combat_world.update_shots(.016)
		check(target.hp<10000,"Echter Schaden durch "+behavior)
	combat_world.pickups.clear()
	for i in range(600): combat_world.drop(Vector2(i*10,0),2)
	var total: float=0
	for p in combat_world.pickups: total+=p.value
	check(total==1200 and combat_world.pickups.size()==250,"XP-Merging erhält Wert")
	combat_world.drop(Vector2.ZERO,5,"gold")
	var coin: Dictionary=combat_world.pickups[-1]
	var before: int=scene.model.gold
	combat_world.collect(coin)
	combat_world.collect(coin)
	check(scene.model.gold==before+5,"Gold nur einmal gesammelt")
	scene.model.hurt(1000)
	check(scene.state=="DEFEAT","Tod und Ergebnis")
	scene.queue_free()
	await process_frame
	print("Ergebnis: ",failures," Fehler")
	quit(1 if failures else 0)
