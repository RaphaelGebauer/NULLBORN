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
	scene.save.path="user://unit_scene_fixture.json"
	scene.save.persistent=false
	root.add_child(scene)
	scene.start_run()
	var e: Dictionary=scene.world.spawn_enemy("wisp",Vector2(80,0))
	for i in range(100):
		scene.world._physics_process(0.016)
	check(scene.model.kills>=1,"Echtes automatisches Projektil tötet Gegner")
	var registry=model.registry
	check(registry.errors.is_empty(),"Registry validiert Ressourcen und Abhängigkeiten")
	for pair in [["weapon",15],["passive",17],["enemy",15],["character",4],["wave",30],["evolution",17],["rune",8],["stage",2]]:
		check(registry.catalogs[pair[0]].size()==pair[1],"Katalog "+pair[0])
	for weapon in registry.catalogs.weapon:
		check(registry.get_def(weapon).upgrades.size()==7 and registry.weapon_values(weapon,8).damage>=registry.weapon_values(weapon,1).damage,"Sieben echte Upgrades: "+weapon)
	model.weapons={"arcane_needle":8,"ash_bow":8,"spark_orbit":8,"thorn_halo":8,"lightning_call":8,"moon_blade":8}
	model.passives={"power_core":5,"clockwork":5,"runner_boots":5,"focus_lens":5,"multiplicity":5,"lasting_seal":5}
	check(model.legal().is_empty(),"6+6 voll und maximal: keine illegalen Angebote")
	check(model.offers()==["reward_gold","reward_heal","reward_xp"],"Drei verschiedene Fallbacks")
	model.weapons={"arcane_needle":1}
	model.passives={}
	check(model.rerolls==0 and model.skips==0 and model.banishes==0,"Fresh runs have no unpaid selection tools")
	model.rerolls=2
	model.skips=1
	model.banishes=1
	var rr: int=model.rerolls
	check(model.reroll().size()==3 and model.rerolls==rr-1,"Reroll verbraucht Charge")
	check(model.banish("power_core").size()==3 and not "power_core" in model.legal() and model.banishes==0,"Banish schließt Item aus")
	check(model.skip() and model.skips==0,"Skip mit XP und Charge")
	model.passives={"blood_vial":5,"power_core":5,"multiplicity":5,"clockwork":5}
	model.recalculate()
	check(model.max_hp==175 and is_equal_approx(model.might,1.5*.93) and model.amount==2 and is_equal_approx(model.projectile_damage,1.15),"Passivwerte deterministisch")
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
	evo.weapons={"arcane_needle":5}
	check(evo.evolution(true)=="","Evolution braucht Katalysator")
	evo.passives={"power_core":4}
	check(evo.evolution(true)=="","Lv4 catalyst cannot evolve weapon")
	evo.passives.power_core=5
	check(evo.evolution(false)=="","Alte Boss-Truhe bleibt nicht evolutionsfähig")
	check(evo.evolution(true)=="star_piercer" and evo.weapons.size()==1 and not evo.weapons.has("arcane_needle"),"Evolution ersetzt Basis, erhält Slotzahl")
	evo.weapons={"ash_bow":5,"frost_shard":5}
	evo.passives={"runner_boots":5}
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
	scene.model.rng.seed=int(OS.get_environment("STERNENBRUCH_TEST_SEED")) if not OS.get_environment("STERNENBRUCH_TEST_SEED").is_empty() else 72047
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
	scene.model.armor=0
	scene.model.runes=[]
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
	check(proc_model.rerolls==0 and proc_model.greed==1.25,"Treasure grants gold without bypassing reroll unlock")
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
	var pace=load("res://scripts/run_model.gd").new()
	pace.recalculate()
	check(is_equal_approx(pace.speed,125.4),"Slower starting movement")
	pace.meta={"long_stride":2}
	pace.recalculate()
	pace.tick(120)
	check(pace.speed>125.4 and is_equal_approx(pace.speed,125.4*1.04),"Long Stride increases movement with game time")
	pace.passives={"momentum_feather":2,"recovery_moss":4}
	pace.recalculate()
	check(pace.speed>125.4*1.04 and pace.regeneration==1,"Momentum Feather and Recovery Moss have real effects")
	var discovery_fixture=load("res://scripts/save_manager.gd").new()
	discovery_fixture.persistent=false
	check(not discovery_fixture.discovered("prism_disc","weapon") and not discovery_fixture.discovered("brann","character"),"Unselected equipment and characters stay hidden")
	discovery_fixture.mark_seen("prism_disc")
	check(discovery_fixture.discovered("prism_disc","weapon"),"Selecting equipment reveals its collection entry")
	var paid_tools=load("res://scripts/run_model.gd").new()
	paid_tools.meta={"rerolls":2,"skips":1,"banishes":1}
	paid_tools.initialize_meta()
	check(paid_tools.rerolls==2 and paid_tools.skips==1 and paid_tools.banishes==1,"Purchased meta ranks grant exact run charges")
	paid_tools.add_rune("treasure")
	check(paid_tools.rerolls==3,"Treasure adds a reroll after its meta unlock")
	var before_requests: int=scene.window_settings.requests
	scene.set_setting("music",.3)
	scene.set_setting("sfx",.4)
	check(scene.window_settings.requests==before_requests,"Audio controls never resize the window")
	check(scene.window_settings.embedded(root,PackedStringArray(["--wid","123"])) and scene.window_settings.embedded(root,PackedStringArray(["--wid=123"])),"Native embedded-window arguments detected")
	check(scene.save.defaults().settings.resolution==2,"New saves default to 1920x1080")
	combat_world.model.passives={}
	combat_world.model.runes=[]
	combat_world.model.crit=0
	combat_world.model.might=1
	combat_world.model.projectile_damage=1
	combat_world.model.amount=0
	for weapon in ["prism_disc","gravity_mine","reaper_gaze"]:
		combat_world.enemies.clear()
		combat_world.shots.clear()
		combat_world.combat.effects.clear()
		var first: Dictionary=combat_world.spawn_enemy("guardian",Vector2(60,0))
		var second: Dictionary=combat_world.spawn_enemy("guardian",Vector2(140,0))
		first.hp=200
		first.max_hp=1000
		second.hp=500
		second.max_hp=1000
		combat_world.grid.rebuild(combat_world.enemies)
		var v: Dictionary=registry.weapon_values(weapon,1)
		combat_world.combat.call("attack_"+v.behavior,weapon,v,first)
		for i in range(90):
			combat_world.combat.update(.016)
			combat_world.update_shots(.016)
		check(first.hp<200,"New weapon damages enemies: "+weapon)
		if weapon=="prism_disc": check(second.hp<500,"Prism Disc bounces to a different enemy")
		if weapon=="gravity_mine": check(second.statuses.has("slow") and second.pos.x<140,"Gravity Mine pulls and slows")
		if weapon=="reaper_gaze": check(first.hp<=146,"Reaper's Gaze deals triple damage below 35% HP")
	combat_world.enemies.clear()
	combat_world.model.passives={"execution_seal":5}
	var wounded: Dictionary=combat_world.spawn_enemy("guardian",Vector2(40,0))
	wounded.hp=300
	wounded.max_hp=1000
	combat_world.hit(wounded,10,{},"test")
	check(wounded.hp==286,"Execution Seal amplifies direct damage to wounded enemies")
	combat_world.model.passives={"frost_thorns":3}
	combat_world.grid.rebuild(combat_world.enemies)
	combat_world.player.invulnerable=0
	combat_world.hurt_player(1)
	check(wounded.hp<286 and wounded.statuses.has("slow"),"Frost Thorns retaliates with actual damage and slow")
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
	scene.save.data=scene.save.defaults()
	scene.menu()
	for child in scene.panel.get_children():
		if child is Button and child.text=="Characters": child.pressed.emit(); break
	var overview_buttons: Array=scene.panel.get_children().filter(func(child):return child is Button)
	check(overview_buttons.size()==1 and overview_buttons[0].text=="Back","Main-menu Characters is read-only")
	var brann_name: String=registry.get_def("brann").display_name
	check(scene.panel.get_children().any(func(child):return child is Label and child.text==brann_name),"Locked overview character shows its name only")
	check(not scene.save.discovered("brann","character"),"Browsing character overview does not mark a selection")
	scene.save.data.unlocked_characters.append("brann")
	scene.character_overview()
	check(scene.panel.get_children().any(func(child):return child is Label and child.text.contains("Ash Bow")),"Unlocked overview character shows details without a launch button")
	scene.character_select()
	check(scene.panel.get_children().any(func(child):return child is Button and child.text.contains("Lyra") and not child.disabled),"New Run still has playable character selection")
	scene.model=load("res://scripts/run_model.gd").new()
	scene.model.weapons={"arcane_needle":5}
	scene.model.passives={"power_core":5}
	scene.save.mark_seen("star_piercer")
	scene.record_inventory()
	var hidden_text: String=scene.pause_recipe_text()
	check(not hidden_text.contains("Star Piercer") and hidden_text.contains("Undiscovered:"),"Owning components or legacy seen flags does not reveal recipes")
	check(not scene.save.discovered("star_piercer","evolution"),"Collection recipes also require a completed evolution")
	check(scene.model.evolution(true)=="star_piercer","Discover through an actual eligible evolution")
	scene.record_inventory()
	check(scene.pause_recipe_text().contains("Star Piercer") and scene.save.discovered("star_piercer","evolution"),"Completed evolution reveals its recipe in pause and collection")
	var reset_save=load("res://scripts/save_manager.gd").new()
	reset_save.path="user://reset_regression_test.json"
	reset_save.data.total_gold=500
	reset_save.mark_evolved("star_piercer")
	reset_save.save()
	var persisted=load("res://scripts/save_manager.gd").new()
	persisted.path=reset_save.path
	check(persisted.load_save() and persisted.discovered("star_piercer","evolution"),"Completed-evolution history survives save/load")
	reset_save.data.meta_powerups={"rerolls":2}
	reset_save.data.settings.master=.2
	reset_save.data.stats.kills=1000
	check(reset_save.reset_all(),"Full reset writes a fresh save")
	check(persisted.load_save() and persisted.data.total_gold==0 and persisted.data.meta_powerups.is_empty() and persisted.data.evolved_recipes.is_empty() and persisted.data.stats.kills==0 and is_equal_approx(persisted.data.settings.master,.8),"Reset persists cleared progression and default settings")
	DirAccess.remove_absolute(reset_save.path)
	scene.save.data.total_gold=500
	scene.return_to_pause=false
	scene.settings()
	check(scene.panel.get_children().any(func(child):return child is Button and child.text=="Reset All Data…"),"Main-menu settings includes a reset entry")
	scene.confirm_reset()
	check(scene.save.data.total_gold==500,"Reset confirmation alone never deletes progress")
	for child in scene.panel.get_children():
		if child is Button and child.text=="Cancel": child.pressed.emit(); break
	check(scene.save.data.total_gold==500 and scene.state=="SETTINGS","Cancel preserves progress and returns to Settings")
	scene.selected_hero="brann"
	scene.selected_stage="ash"
	scene.confirm_reset()
	for child in scene.panel.get_children():
		if child is Button and child.text=="Reset Everything": child.pressed.emit(); break
	check(scene.save.data==scene.save.defaults() and scene.model==null and scene.selected_hero=="lyra" and scene.selected_stage=="mist" and scene.state=="MENU","Confirmed reset clears all data and stale session selections")
	var slow_model=load("res://scripts/run_model.gd").new()
	slow_model.recalculate()
	check(scene.save.META.size()==20,"Twenty permanent meta upgrades are available")
	check(is_equal_approx(slow_model.opening_factor("spawn_rate"),.4) and is_equal_approx(slow_model.opening_factor("enemy_speed"),.65),"Fresh run has lower density and enemy speed")
	slow_model.time=240
	check(is_equal_approx(slow_model.opening_factor("spawn_rate"),.7) and is_equal_approx(slow_model.opening_factor("attack_interval"),1.1),"Opening pace ramps smoothly at its midpoint")
	slow_model.time=480
	check(is_equal_approx(slow_model.opening_factor("projectile_speed"),1) and is_equal_approx(slow_model.opening_factor("enemy_speed"),1),"Opening modifiers reach normal pace after eight minutes")
	slow_model.time=0
	var pace_world=load("res://scenes/game.tscn").instantiate()
	pace_world.model=slow_model
	root.add_child(pace_world)
	pace_world.set_physics_process(false)
	pace_world.player.set_physics_process(false)
	var early_mite: Dictionary=pace_world.spawn_enemy("mite",Vector2(100,0))
	pace_world.grid.rebuild(pace_world.enemies)
	pace_world.update_enemy(early_mite,.1)
	check(is_equal_approx(early_mite.velocity.length(),97.5),"Actual early enemy movement is slower")
	for hero_id in registry.catalogs.character:
		slow_model.hero=hero_id
		slow_model.recalculate()
		check(is_equal_approx(slow_model.speed,registry.get_def(hero_id).values.speed*.57) and slow_model.speed>early_mite.velocity.length(),"Requested base speed remains above early mite speed: "+hero_id)
	slow_model.hero="lyra"
	slow_model.recalculate()
	pace_world.combat.update(.001)
	check(is_equal_approx(pace_world.combat.timers.arcane_needle,1.02),"Actual opening auto-attack interval is slower")
	check(is_equal_approx(pace_world.shots[0].velocity.length(),360),"Actual friendly projectile starts slower")
	pace_world.projectile(Vector2(400,0),Vector2(150,0),{"damage":1},"test",0,true)
	check(is_equal_approx(pace_world.shots[-1].velocity.length(),120),"Hostile projectiles are slowed as well")
	slow_model.meta={"projectile_speed":5,"battle_rhythm":5,"pickup_speed":5,"evasive_instinct":5,"speed":5}
	slow_model.recalculate()
	check(slow_model.speed>125.4 and slow_model.projectile_speed==1.3 and slow_model.pickup_speed==1.6,"Movement, missile and gathering meta upgrades take effect")
	slow_model.time=600
	slow_model.tick(0)
	check(is_equal_approx(slow_model.cooldown,.5),"Battle Rhythm accelerates weapons over time")
	var healthy_speed: float=slow_model.speed
	slow_model.hp=slow_model.max_hp*.4
	slow_model.tick(0)
	check(slow_model.speed>healthy_speed,"Evasive Instinct adds escape speed at low HP")
	slow_model.hp=slow_model.max_hp
	slow_model.tick(0)
	check(is_equal_approx(slow_model.speed,healthy_speed),"Escape bonus ends on recovery without stacking")
	slow_model.meta={}
	slow_model.recalculate()
	pace_world.drop(Vector2(80,0),1)
	pace_world.update_pickups(.1)
	var normal_pickup_x: float=pace_world.pickups[0].pos.x
	pace_world.pickups[0].pos=Vector2(80,0)
	pace_world.pickups[0].speed=60
	slow_model.meta={"pickup_speed":5}
	slow_model.recalculate()
	pace_world.update_pickups(.1)
	check(pace_world.pickups[0].pos.x<normal_pickup_x,"Gathering Flow increases actual pickup movement")
	pace_world.queue_free()
	var e1_save=load("res://scripts/save_manager.gd").new()
	e1_save.path="user://e1_migration_test.json"
	var old_data: Dictionary=e1_save.defaults()
	old_data.erase("starlight")
	old_data.erase("constellation_nodes")
	old_data.total_gold=1234
	old_data.meta_powerups={"speed":3,"battle_rhythm":2}
	old_data.evolved_recipes=["star_piercer"]
	old_data.settings.music=.15
	var old_file:=FileAccess.open(e1_save.path,FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old_data))
	old_file.close()
	check(e1_save.load_save() and e1_save.data.starlight==0 and e1_save.data.constellation_nodes.is_empty(),"E1 old save gains additive star-map defaults")
	check(e1_save.data.total_gold==1234 and e1_save.data.meta_powerups.speed==3 and e1_save.data.evolved_recipes==["star_piercer"] and is_equal_approx(e1_save.data.settings.music,.15),"E1 migration preserves gold, upgrades, recipes and settings")
	check(not e1_save.valid({"version":1,"starlight":-1}) and not e1_save.valid({"version":1,"starlight":1.5}),"E1 rejects invalid starlight values")
	check(not e1_save.valid({"version":1,"constellation_nodes":["node","node"]}),"E1 rejects duplicate constellation IDs")
	e1_save.data.starlight=9
	e1_save.reset_all()
	check(e1_save.data.starlight==0 and e1_save.data.constellation_nodes.is_empty(),"E1 full reset includes new persistent fields")
	DirAccess.remove_absolute(e1_save.path)
	var stats=load("res://scripts/run_statistics.gd").new()
	stats.record_damage("arcane_needle",100,15,true,0)
	stats.record_damage("star_piercer",20,20,false,1)
	check(stats.total_damage==35 and stats.critical_hits==1 and stats.highest_hit==20,"E1 statistics clamp overkill and count real crits")
	check(stats.damage_by_source.arcane_needle==15 and stats.damage_by_source.star_piercer==20,"E1 base and evolved sources stay separate")
	stats.record_damage("Elemental Reactions",10,10,false,15)
	check(stats.highest_ten_second_dps==3.5 and stats.bucket_seconds.size()==11,"E1 bounded rolling DPS buckets age out old hits")
	var health_model=load("res://scripts/run_model.gd").new()
	health_model.hp=95
	health_model.heal(30)
	health_model.hurt(150)
	check(health_model.statistics.total_healing==5 and health_model.statistics.damage_taken==100,"E1 health statistics record actual healing and damage")
	check(registry.elements_for_weapon("arcane_needle").is_empty() and registry.elements_for_weapon("dusk_storm")==["fire","frost"],"E1 neutral and fusion element tags form a unique union")
	var rift=load("res://scripts/rift_instability.gd").new()
	for boundary in [[24.99,0],[25,1],[49.99,1],[50,2],[74.99,2],[75,3],[89.99,3],[90,4],[100,4]]:
		rift.change(boundary[0]-rift.value)
		check(rift.band()==boundary[1],"E1 instability threshold "+str(boundary[0]))
	rift.change(-1000)
	rift.advance(1800)
	check(is_equal_approx(rift.value,54) and rift.peak==100,"E1 clamp, backward band change and baseline gain")
	var normal_model=load("res://scripts/run_model.gd").new()
	var quick_model=load("res://scripts/run_model.gd").new()
	quick_model.fast=true
	normal_model.tick(2)
	quick_model.tick(1)
	check(normal_model.run_delta==quick_model.run_delta and normal_model.time==quick_model.time,"E1 quick mode shares an explicit run-time delta")
	scene.queue_free()
	await process_frame
	await process_frame
	print("Ergebnis: ",failures," Fehler")
	quit(1 if failures else 0)
