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
	scene.save.persistent=false
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
		combat_world.model.weapons={}
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
	var evo=load("res://scripts/run_model.gd").new()
	evo.weapons={"arcane_needle":8}
	check(evo.evolution(true)=="","Evolution braucht Katalysator")
	evo.passives={"power_core":1}
	check(evo.evolution(false)=="","Alte Boss-Truhe bleibt nicht evolutionsfähig")
	check(evo.evolution(true)=="star_piercer" and evo.weapons.size()==1 and not evo.weapons.has("arcane_needle"),"Evolution ersetzt Basis, erhält Slotzahl")
	evo.weapons={"ash_bow":8,"frost_shard":8}
	evo.passives={"runner_boots":1}
	check(evo.evolution(true)=="dusk_storm" and evo.weapons.size()==1,"Fusion hat Vorrang und gibt Slot frei")
	for recipe in registry.catalogs.evolution.values():
		var v: Dictionary=registry.weapon_values(recipe.id,1)
		check(v.damage>0 and v.get("evolved",false),"Funktionale Evolutionsdaten "+recipe.id)
	for pair in [[5,"astral_guardian"],[10,"void_queen"],[29,"storm_core"]]:
		combat_world.enemies.clear()
		scene.model.time=pair[0]*60
		combat_world._physics_process(.016)
		check(combat_world.enemies.any(func(enemy):return enemy.kind==pair[1]),"Bosswelle "+str(pair[0]))
	var winner=load("res://scripts/run_model.gd").new()
	var results: Array=[]
	winner.ended.connect(func(v):results.append(v))
	winner.time=1799.9
	winner.tick(.2)
	winner.finish(true)
	winner.hurt(999)
	check(results==[true],"Sieg bei 30:00 und genau ein Endereignis")
	scene.events=["LEVELUP","CHEST","RUNE"]
	scene.show_event()
	check(scene.state=="LEVELUP" and paused,"Level-Modal pausiert SceneTree")
	var clock: float=scene.model.time
	var combat_clock: float=combat_world.combat.elapsed
	await process_frame
	await physics_frame
	check(scene.model.time==clock and combat_world.combat.elapsed==combat_clock,"Pause stoppt Timer, Kampf und Welt")
	scene.choose(0)
	scene.show_event()
	check(scene.state=="CHEST","Truhe nach Level-up serialisiert")
	scene.resume()
	scene.show_event()
	check(scene.state=="RUNE" and scene.cards.size()==3,"Runensegen nach Truhe serialisiert")
	scene.choose_rune(0)
	check(scene.state=="RUNNING" and not paused and scene.events.is_empty(),"Drei Modals ohne Deadlock aufgelöst")
	var saver=load("res://scripts/save_manager.gd").new()
	saver.path="user://automated_test_save.json"
	if FileAccess.file_exists(saver.path): DirAccess.remove_absolute(saver.path)
	check(saver.load_save() and saver.data.total_gold==0,"Save-Defaults")
	check(not saver.buy("might") and saver.data.total_gold==0,"Shop blockiert unbezahlbaren Kauf")
	saver.data.total_gold=1000
	check(saver.buy("might") and saver.data.meta_powerups.might==1 and saver.data.total_gold==925,"Shop-Kauf und Preis")
	saver.data.settings.music=.15
	saver.save()
	var reloaded=load("res://scripts/save_manager.gd").new()
	reloaded.path=saver.path
	check(reloaded.load_save() and reloaded.data.meta_powerups.might==1 and is_equal_approx(reloaded.data.settings.music,.15),"Save/Load inklusive Settings")
	var corrupt:=FileAccess.open(saver.path,FileAccess.WRITE)
	corrupt.store_string("{ kaputt")
	corrupt.close()
	check(not reloaded.load_save() and reloaded.data.total_gold==0 and FileAccess.file_exists(saver.path+".corrupt.bak"),"Korrupter Save wird gesichert und abgefangen")
	check(not saver.valid({"version":1,"settings":{"master":"falsch"}}),"Save-Schema lehnt falsche Typen ab")
	var run_for_save=load("res://scripts/run_model.gd").new()
	run_for_save.kills=1000
	run_for_save.bosses=1
	run_for_save.time=1800
	run_for_save.gold=100
	run_for_save.curse=.5
	saver.persistent=false
	saver.finish_run(run_for_save,true)
	var wallet: int=saver.data.total_gold
	saver.finish_run(run_for_save,true)
	check(wallet==1075 and saver.data.total_gold==wallet and saver.data.stats.runs==1,"Gold mit Fluchbonus nur einmal verbucht")
	check(saver.data.unlocked_characters.size()==4 and "ash" in saver.data.unlocked_stages,"Vier Helden und zweite Arena durch echte Erfolge freigeschaltet")
	for path in [saver.path,saver.path+".corrupt.bak"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var old_health: float=scene.model.hp
	scene.model.hp=100
	scene.world.player.invulnerable=0
	scene.world.hurt_player(10)
	var injured: float=scene.model.hp
	scene.world.hurt_player(10)
	check(injured==90 and scene.model.hp==90,"I-Frames verhindern mehrfachen Kontaktschaden")
	scene.model.armor=4
	scene.world.player.invulnerable=0
	scene.world.hurt_player(10)
	check(scene.model.hp==84,"Rüstung korrekt abgezogen")
	scene.model.hp=old_health
	var regen=load("res://scripts/run_model.gd").new()
	regen.hp=50
	regen.regeneration=2
	regen.tick(3)
	check(regen.hp==56,"Regeneration nutzt Spielzeit")
	var hp_ratio: float=regen.hp/regen.max_hp
	regen.passives={"blood_vial":5}
	regen.recalculate()
	check(is_equal_approx(regen.hp/regen.max_hp,hp_ratio),"Max-HP-Änderung erhält HP-Anteil")
	for id in registry.catalogs.rune:
		var rune_model=load("res://scripts/run_model.gd").new()
		rune_model.add_rune(id)
		check(rune_model.runes==[id],"Rune registriert: "+id)
	var proc_model=load("res://scripts/run_model.gd").new()
	proc_model.hp=50
	proc_model.add_rune("blood_moon")
	for i in range(600): proc_model.kill()
	check(proc_model.hp==80,"Blutmond heilt höchstens 30 HP pro Minute")
	proc_model.add_rune("resonance")
	for i in range(20): proc_model.kill()
	check(proc_model.resonance==3,"Kampfresonanz alle 20 Kills")
	proc_model.tick(3.1)
	check(proc_model.resonance==0,"Resonanz läuft in Spielzeit aus")
	proc_model.add_rune("treasure")
	check(proc_model.rerolls==3 and proc_model.greed==1.25,"Schatzsucher gibt Goldbonus und Reroll")
	combat_world.enemies.clear()
	combat_world.model.weapons={}
	combat_world.model.runes=[]
	combat_world.model.crit=0
	var status_enemy: Dictionary=combat_world.spawn_enemy("guardian",Vector2(100,0))
	status_enemy.hp=1000
	status_enemy.max_hp=1000
	status_enemy.speed=0
	combat_world.hit(status_enemy,1,{"burn":1,"poison":1,"slow":1},"test")
	var status_health: float=status_enemy.hp
	combat_world.update_enemy(status_enemy,1.01)
	check(status_enemy.hp==status_health-7 and status_enemy.statuses.has("slow"),"Brennen/Gift ticken und Slow bleibt aktiv")
	combat_world.update_enemy(status_enemy,4.1)
	check(status_enemy.statuses.is_empty(),"Status-Effekte laufen aus")
	var amount_before: int=combat_world.model.amount
	combat_world.model.amount=0
	combat_world.model.runes=["shard_star"]
	combat_world.shots.clear()
	combat_world.combat.attack_needle("arcane_needle",registry.weapon_values("arcane_needle",1),status_enemy)
	check(combat_world.shots.size()==2,"Splitterstern erzeugt zusätzliches echtes Projektil")
	combat_world.model.amount=amount_before
	combat_world.model.runes=["time_anchor"]
	var duration_values: Dictionary=registry.weapon_values("sun_beam",1)
	check(is_equal_approx(combat_world.combat.params(duration_values).duration,duration_values.duration*combat_world.model.duration*1.25),"Zeitanker verlängert echten Beam")
	scene.model.hurt(1000)
	check(scene.state=="DEFEAT","Tod und Ergebnis")
	# These screens build real Controls; catch stale paths and signal/closure errors.
	scene.menu()
	scene.character_select()
	check(scene.panel.get_child_count()>=6,"Charaktermenü gebaut")
	scene.stage_select()
	scene.shop()
	scene.settings()
	scene.collection()
	check(scene.panel.get_child_count()>=3,"Shop, Einstellungen, Sammlung gebaut")
	scene.queue_free()
	await process_frame
	await process_frame
	print("Ergebnis: ",failures," Fehler")
	quit(1 if failures else 0)
