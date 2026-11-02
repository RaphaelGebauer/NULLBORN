extends Node
const Model = preload("res://scripts/run_model.gd")
const World = preload("res://scripts/world.gd")
var model: RefCounted
var world: Node2D
var ui: CanvasLayer
var panel: VBoxContainer
var hud: Label
var events: Array = []
var state: String = "MENU"
var cards: Array = []
var banishing: bool = false
var selected_hero: String = "lyra"
var selected_stage: String = "mist"
var selected_fast: bool = false
var selected_curse: float = 0
var catalog=preload("res://scripts/data/registry.gd").new()
var hp_bar: ProgressBar
var xp_bar: ProgressBar
var build_label: Label
var boss_label: Label
var save=preload("res://scripts/save_manager.gd").new()
var audio: Node
var preview: Control
var preview_time: float=0
var return_to_pause: bool=false
var window_settings=preload("res://scripts/window_settings.gd").new()
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	save.load_save()
	audio=preload("res://scripts/audio_manager.gd").new()
	add_child(audio)
	setup_input()
	apply_settings()
	ui=CanvasLayer.new()
	add_child(ui)
	menu()
func setup_input() -> void:
	var keys := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var event:=InputEventKey.new()
			event.physical_keycode=key
			InputMap.action_add_event(action,event)
		var stick:=InputEventJoypadMotion.new()
		stick.axis=JOY_AXIS_LEFT_X if action in ["move_left","move_right"] else JOY_AXIS_LEFT_Y
		stick.axis_value=-1 if action in ["move_left","move_up"] else 1
		InputMap.action_add_event(action,stick)
	var start:=InputEventJoypadButton.new()
	start.button_index=JOY_BUTTON_START
	InputMap.action_add_event("ui_cancel",start)
func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
func box(title: String, subtitle: String="") -> void:
	clear_ui()
	var background:=ColorRect.new()
	background.color=Color(0.015,0.025,0.06,0.94)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)
	background.draw.connect(func():
		var size: Vector2=background.size
		for i in range(65):
			var pos:=Vector2(fposmod(i*173.7,size.x),fposmod(i*i*31.2,size.y))
			background.draw_circle(pos,1.0+(i%3)*.5,Color(.35,.7,.75,.1))
		background.draw_arc(Vector2(size.x*.5,size.y*.5),280,-.6,3.5,70,Color(.2,.6,.6,.07),2))
	var scroll:=ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	ui.add_child(scroll)
	var center:=CenterContainer.new()
	center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	panel=VBoxContainer.new()
	panel.custom_minimum_size=Vector2(700,0)
	panel.add_theme_constant_override("separation",16)
	center.add_child(panel)
	label(title,36)
	if subtitle!="": label(subtitle,18)
func label(text: String, size: int=20) -> Label:
	var node:=Label.new()
	node.text=text
	node.add_theme_font_size_override("font_size",size)
	if size>=30: node.modulate=Color("f0d5a1")
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(node)
	return node
func button(text: String, action: Callable) -> Button:
	var node:=Button.new()
	node.text=text
	node.custom_minimum_size.y=52
	node.add_theme_font_size_override("font_size",20)
	node.pressed.connect(func(): audio.play("choose"); action.call())
	style_button(node)
	panel.add_child(node)
	if panel.get_child_count()<=3: focus_button.call_deferred(node)
	return node
func menu() -> void:
	get_tree().paused=false
	state="MENU"
	if is_instance_valid(world):
		var previous_world: Node2D=world
		world=null
		if previous_world.get_parent()==self: remove_child(previous_world)
		previous_world.queue_free()
	box("S T E R N E N B R U C H","Survive the rift. Forge your star.")
	button("New Run",character_select)
	button("Characters",character_overview)
	button("Collection / Bestiary",collection)
	button("Meta-Upgrades · %d Gold" % save.data.total_gold,shop)
	button("Settings",func(): return_to_pause=false; settings())
	if save.warning!="": label(save.warning,14)
	button("Quit",func(): get_tree().quit())
func start_run() -> void:
	model=Model.new()
	model.rng.randomize()
	model.hero=selected_hero
	model.stage=selected_stage
	model.fast=selected_fast
	model.curse=selected_curse
	model.weapons={catalog.get_def(selected_hero).values.weapon:1}
	model.constellation_nodes=save.data.constellation_nodes.duplicate()
	model.meta=save.data.meta_powerups.duplicate()
	model.unlocked_weapons=save.data.unlocked_weapons.duplicate()
	model.initialize_meta()
	save.mark_seen(selected_hero)
	model.recalculate()
	model.inventory_changed.connect(record_inventory)
	model.kills_changed.connect(check_unlocks)
	model.rune_changed.connect(record_inventory)
	events.clear()
	model.modal_requested.connect(func(kind): events.append(kind))
	model.ended.connect(result)
	world=preload("res://scenes/game.tscn").instantiate()
	world.model=model
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	world.sound_requested.connect(audio.play)
	world.screen_shake=save.data.settings.screen_shake
	world.reduce_flash=save.data.settings.reduce_flash
	world.player.reduce_flash=save.data.settings.reduce_flash
	world.damage_texts=save.data.settings.damage_texts
	record_inventory()
	events.append("RUNE")
	resume()
	show_event()
func resume() -> void:
	if model.finished: return
	state="RUNNING"
	clear_ui()
	hud=Label.new()
	hud.position=Vector2(20,12)
	hud.add_theme_font_size_override("font_size",21)
	ui.add_child(hud)
	hp_bar=ProgressBar.new()
	hp_bar.position=Vector2(20,46)
	hp_bar.size=Vector2(300,18)
	hp_bar.show_percentage=false
	hp_bar.add_theme_stylebox_override("fill",flat(Color("d66879")))
	hp_bar.add_theme_stylebox_override("background",flat(Color("292a42")))
	ui.add_child(hp_bar)
	xp_bar=ProgressBar.new()
	xp_bar.position=Vector2(340,46)
	xp_bar.size=Vector2(600,18)
	xp_bar.show_percentage=false
	xp_bar.add_theme_stylebox_override("fill",flat(Color("57cfc5")))
	xp_bar.add_theme_stylebox_override("background",flat(Color("292a42")))
	ui.add_child(xp_bar)
	build_label=Label.new()
	build_label.position=Vector2(20,72)
	build_label.add_theme_font_size_override("font_size",15)
	ui.add_child(build_label)
	boss_label=Label.new()
	boss_label.position=Vector2(20,155)
	boss_label.modulate=Color("ffb1a5")
	ui.add_child(boss_label)
	get_tree().paused=false
func build_text() -> String:
	var rows: Array=[]
	for pair in [["Weapons",model.weapons],["Passives",model.passives]]:
		var names: Array=[]
		for id in pair[1]: names.append("◆ %s %d" % [model.title(id),pair[1][id]])
		for i in range(6-pair[1].size()): names.append("◇")
		rows.append(pair[0]+": "+"  ·  ".join(names))
	var names: Array=[]
	for id in model.runes: names.append(model.title(id))
	rows.append("Runes: "+" · ".join(names))
	return "\n".join(rows)
func _process(_delta: float) -> void:
	if is_instance_valid(preview) and preview.is_inside_tree():
		preview_time+=_delta
		preview.queue_redraw()
	if state=="RUNNING":
		hud.text="HP %d/%d   |   LV %d   XP %d/%d   |   %02d:%02d   |   %d Kills   |   %d Gold   |   Wave %d" % [model.hp,model.max_hp,model.level,model.xp,model.required_xp(),int(model.time)/60,int(model.time)%60,model.kills,model.gold,mini(30,int(model.time)/60+1)]
		hp_bar.max_value=model.max_hp
		hp_bar.value=model.hp
		xp_bar.max_value=model.required_xp()
		xp_bar.value=model.xp
		build_label.text=build_text()
		boss_label.text=""
		for e in world.enemies:
			save.mark_seen(e.kind)
			if e.boss: boss_label.text+="%s   %d / %d HP\n" % [model.title(e.kind),maxi(0,int(e.hp)),int(e.max_hp)]
		var seconds: int=int(model.time)%60
		if seconds>=50 and int(model.time)/60 in [4,9,14,19,24,28]: boss_label.text+="⚠ Boss arrives in %d seconds" % (60-seconds)
		if seconds<3: boss_label.text+="\n"+catalog.get_def("wave_%02d" % mini(29,int(model.time)/60)).display_name
		if not events.is_empty(): show_event()
func show_event() -> void:
	if model.finished: return
	state=events.pop_front()
	get_tree().paused=true
	banishing=false
	match state:
		"LEVELUP":
			cards=model.offers()
			redraw_cards()
		"RUNE":
			var pool: Array=catalog.catalogs.rune.keys().filter(func(id):return not id in model.runes)
			cards=[]
			while cards.size()<3 and not pool.is_empty(): cards.append(pool.pop_at(model.rng.randi_range(0,pool.size()-1)))
			box("RUNE BLESSING","Choose a blessing for this run. No equipment slot required.")
			for i in range(cards.size()): button("%d · %s\n%s" % [i+1,model.title(cards[i]),catalog.get_def(cards[i]).description],choose_rune.bind(i))
		"CHEST","CHEST_EVOLUTION": open_chest(state=="CHEST_EVOLUTION")
func choose_rune(index: int) -> void:
	if state!="RUNE" or index>=cards.size(): return
	state="TRANSITION"
	model.add_rune(cards[index])
	resume()
func open_chest(eligible: bool) -> void:
	var evolution: String=model.evolution(eligible)
	var reward: int=model.rng.randi_range(60,140)
	var lines: String=""
	if evolution!="": lines="New Evolution!\n"+model.title(evolution)+"\n"+catalog.get_def(evolution).description
	else:
		var owned: Array=[]
		for id in model.legal():
			if model.weapons.has(id) or model.passives.has(id): owned.append(id)
		if owned.is_empty(): reward=100
		else:
			var rewards: int=1
			if model.rng.randf()<minf(.12,.015*model.luck): rewards=2
			if model.rng.randf()<minf(.025,.003*model.luck): rewards=3
			for i in range(rewards):
				if owned.is_empty(): break
				var id: String=owned.pop_at(model.rng.randi_range(0,owned.size()-1))
				model.upgrade(id)
				lines+="Upgraded: "+model.title(id)+"\n"
	model.gold+=roundi(reward*model.greed)
	state="CHEST"
	box("STAR CHEST",lines+"\n+%d Gold" % roundi(reward*model.greed))
	panel.modulate.a=0
	var tween:=panel.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel,"modulate:a",1.0,.25)
	button("Claim rewards",resume)
func choose(index: int) -> void:
	if state!="LEVELUP": return
	if banishing:
		var next: Array=model.banish(cards[index])
		if next.is_empty(): return
		banishing=false
		cards=next
		redraw_cards()
		return
	state="TRANSITION"
	model.upgrade(cards[index])
	world.player.invulnerable=maxf(world.player.invulnerable,0.3)
	resume()
func result(victory: bool) -> void:
	var added: Array=save.finish_run(model,victory)
	state="VICTORY" if victory else "DEFEAT"
	get_tree().paused=true
	box("THE RIFT IS SEALED" if victory else "YOUR STAR FADES","Level %d · %d Kills · %02d:%02d" % [model.level,model.kills,int(model.time)/60,int(model.time)%60])
	label("%d Gold earned (curse bonus included) · %d Bosses\n%s\nUnlocked: %s" % [roundi(model.gold*(1+model.curse)),model.bosses,build_text(),", ".join(added) if not added.is_empty() else "—"],16)
	button("Try Again",func(): menu(); start_run())
	button("Main Menu",menu)
func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and is_instance_valid(world) and state=="RUNNING":
		if event.keycode in [KEY_F6,KEY_F7,KEY_F8,KEY_F9]:
			var times: Dictionary={KEY_F6:590,KEY_F7:600,KEY_F8:1200,KEY_F9:1740}
			model.time=times[event.keycode]
			world.minute=-1
		if event.keycode==KEY_F10: model.add_xp(500)
		if event.keycode==KEY_F11:
			model.weapons={"arcane_needle":8,"ash_bow":8,"frost_shard":8}
			model.passives={"power_core":5,"runner_boots":5}
			model.recalculate()
		if event.keycode==KEY_F12:
			world.drop(world.player.position,1,"chest",true)
			model.gold+=500
	if event.is_action_pressed("ui_cancel") and state in ["RUNNING","PAUSED"]:
		if state=="PAUSED": resume()
		else:
			state="PAUSED"
			get_tree().paused=true
			box("PAUSE",build_text())
			label(pause_recipe_text(),14)
			button("Resume",resume)
			button("Settings",func(): return_to_pause=true; settings())
			button("End Run",confirm_end)
	if event is InputEventKey and event.pressed and not event.echo and state=="RUNE":
		if event.keycode in [KEY_1,KEY_2,KEY_3]: choose_rune(event.keycode-KEY_1)
	if event is InputEventKey and event.pressed and not event.echo and state=="LEVELUP":
		if event.keycode in [KEY_1,KEY_2,KEY_3]: choose(event.keycode-KEY_1)
		if event.keycode==KEY_R: reroll_cards()
		if event.keycode==KEY_T: skip_cards()
		if event.keycode==KEY_B: toggle_banish()

func focus_button(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()

func redraw_cards() -> void:
	box("BANISH: Select a card" if banishing else "STAR ASCENT · Level %d" % model.level,"Choose an upgrade. The world is paused.")
	for i in range(3): button("%d  ·  %s\n%s" % [i+1,model.title(cards[i]),model.describe(cards[i])],choose.bind(i))
	button("Reroll [R] · %d" % model.rerolls,reroll_cards).disabled=model.rerolls<=0
	panel.get_child(-1).visible=model.meta.get("rerolls",0)>0
	button("Skip [T] · %d" % model.skips,skip_cards).disabled=model.skips<=0
	panel.get_child(-1).visible=model.meta.get("skips",0)>0
	button("Banish [B] · %d" % model.banishes,toggle_banish).disabled=model.banishes<=0
	panel.get_child(-1).visible=model.meta.get("banishes",0)>0
func reroll_cards() -> void:
	if state!="LEVELUP": return
	var next: Array=model.reroll()
	if not next.is_empty():
		cards=next
		banishing=false
		redraw_cards()
func skip_cards() -> void:
	if state=="LEVELUP" and model.skip():
		banishing=false
		resume()
func toggle_banish() -> void:
	if state=="LEVELUP" and model.banishes>0:
		banishing=not banishing
		redraw_cards()

func character_select() -> void:
	state="MENU"
	box("CHOOSE YOUR STAR","Each hero starts with a unique weapon.")
	for id in catalog.catalogs.character:
		var d: Resource=catalog.get_def(id)
		var locked: bool=not id in save.data.unlocked_characters
		button(d.display_name if locked else character_details(id),select_hero.bind(id)).disabled=locked
	preview=Control.new()
	preview.custom_minimum_size=Vector2(700,55)
	panel.add_child(preview)
	preview.draw.connect(func():
		var center: Vector2=preview.size*.5
		preview.draw_arc(center,22,preview_time,preview_time+TAU*.8,24,Color("64c5c6"),2)
		preview.draw_colored_polygon(PackedVector2Array([center+Vector2(0,-15),center+Vector2(11,10),center+Vector2(-11,10)]),Color("aaf6e5")))
	button("Back",menu)
func select_hero(id: String) -> void:
	if not id in save.data.unlocked_characters: return
	save.mark_seen(id)
	save.save()
	selected_hero=id
	stage_select()
func stage_select() -> void:
	box("AT THE EDGE OF THE RIFT","Choose your arena, pace and optional curse.")
	for id in catalog.catalogs.stage:
		button(("◆ " if selected_stage==id else "◇ ")+catalog.get_def(id).display_name+(" · Locked: first victory" if not id in save.data.unlocked_stages else ""),func(): selected_stage=id; stage_select()).disabled=not id in save.data.unlocked_stages
	button("Mode: "+("Quick · 15 minutes" if selected_fast else "Normal · 30 minutes"),func(): selected_fast=not selected_fast; stage_select())
	var row:=HBoxContainer.new()
	panel.add_child(row)
	var text:=Label.new()
	text.text="Curse: +%d %% enemies / bonus gold" % roundi(selected_curse*100)
	row.add_child(text)
	var slider:=HSlider.new()
	slider.min_value=0
	slider.max_value=.5
	slider.step=.1
	slider.value=selected_curse
	slider.custom_minimum_size.x=300
	slider.value_changed.connect(func(v): selected_curse=v; text.text="Curse: +%d %% enemies / bonus gold" % roundi(v*100))
	row.add_child(slider)
	button("Enter the Rift",start_run)
	button("Back",character_select)
func collection() -> void:
	box("COLLECTION / BESTIARY","%d discoveries · %d achievements · %d total kills" % [save.data.seen.size(),save.data.achievements.size(),save.data.stats.kills])
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(900,450)
	panel.add_child(scroll)
	var text:=RichTextLabel.new()
	text.custom_minimum_size=Vector2(850,0)
	text.fit_content=true
	var lines: String=""
	for kind in catalog.catalogs:
		lines+="\n"+{"weapon":"WEAPONS","passive":"PASSIVES","enemy":"BESTIARY","character":"HEROES","wave":"WAVES","evolution":"RECIPES","rune":"RUNES","stage":"ARENAS"}[kind]+"\n"
		for d in catalog.catalogs[kind].values():
			var discovered: bool=save.discovered(d.id,kind)
			lines+=(d.display_name+" · "+d.description if discovered else "??? · Not yet discovered")+"\n"
	text.text=lines
	scroll.add_child(text)
	button("Back",menu)
func confirm_end() -> void:
	box("END THIS RUN?","This ends the run as a defeat. Earned gold is kept.")
	button("Keep Playing",resume)
	button("Finish Run",func(): model.finish(false))

func record_inventory() -> void:
	for owned in [model.weapons.keys(),model.passives.keys(),model.runes]:
		for id in owned: save.mark_seen(id)
	for id in model.evolutions: save.mark_evolved(id)
	save.save()
	check_unlocks()
func check_unlocks() -> void:
	var added: Array=save.unlocks(model.kills,model.bosses,model.time,false,model.evolutions,model.passives)
	if not added.is_empty(): save.save()
func shop() -> void:
	box("STAR FORGE · %d Gold" % save.data.total_gold,"Permanent upgrades. Take effect on your next run.")
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(800,430)
	panel.add_child(scroll)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	for id in save.META:
		var d: Dictionary=save.META[id]
		var rank: int=save.data.meta_powerups.get(id,0)
		var node:=Button.new()
		node.text="%s · %d/%d · %s · %s" % [d.name,rank,d.max,d.effect,"MAX" if rank>=d.max else str(save.price(id))+" Gold"]
		node.custom_minimum_size.y=48
		node.disabled=rank>=d.max or save.data.total_gold<save.price(id)
		node.pressed.connect(func(): save.buy(id); shop())
		style_button(node)
		rows.add_child(node)
	button("Back",menu)
func apply_settings(key: String="") -> void:
	var values: Dictionary=save.data.settings
	audio.configure(values)
	window_settings.apply(get_window(),values,key)
	for action in ["move_left","move_right","move_up","move_down"]: InputMap.action_set_deadzone(action,clampf(values.deadzone,.05,.5))
	get_window().content_scale_factor=clampf(values.ui_scale,.8,1.2)
	if is_instance_valid(world):
		world.screen_shake=values.screen_shake
		world.reduce_flash=values.reduce_flash
		world.player.reduce_flash=values.reduce_flash
		world.damage_texts=values.damage_texts
func set_setting(key: String,value: Variant) -> void:
	save.data.settings[key]=value
	apply_settings(key)
	save.save()
	if key=="fullscreen": settings()
func settings() -> void:
	box("SETTINGS")
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(780,460)
	panel.add_child(scroll)
	var rows:=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12)
	scroll.add_child(rows)
	for pair in [["master","Master Volume",0,1,.05],["music","Music",0,1,.05],["sfx","Effects",0,1,.05],["deadzone","Controller Deadzone",.05,.5,.05],["ui_scale","UI Scale",.8,1.2,.1]]:
		var row:=HBoxContainer.new()
		rows.add_child(row)
		var text:=Label.new()
		text.text=pair[1]
		text.custom_minimum_size.x=260
		row.add_child(text)
		var slider:=HSlider.new()
		slider.min_value=pair[2]
		slider.max_value=pair[3]
		slider.step=pair[4]
		slider.value=save.data.settings[pair[0]]
		slider.custom_minimum_size=Vector2(300,30)
		slider.value_changed.connect(func(v): set_setting(pair[0],v))
		row.add_child(slider)
	for pair in [["fullscreen","Fullscreen"],["screen_shake","Screen Shake"],["reduce_flash","Reduce Flashes"],["damage_texts","Damage Numbers"]]:
		var toggle:=CheckButton.new()
		toggle.text=pair[1]
		toggle.button_pressed=save.data.settings[pair[0]]
		toggle.disabled=pair[0]=="fullscreen" and window_settings.embedded(get_window())
		toggle.toggled.connect(func(v): set_setting(pair[0],v))
		rows.add_child(toggle)
	var resolution:=OptionButton.new()
	for option in ["1280 × 720","1600 × 900","1920 × 1080"]: resolution.add_item(option)
	resolution.selected=clampi(int(save.data.settings.resolution),0,2)
	resolution.disabled=window_settings.embedded(get_window()) or save.data.settings.fullscreen
	resolution.item_selected.connect(func(v): set_setting("resolution",v))
	rows.add_child(resolution)
	if window_settings.embedded(get_window()):
		var hint:=Label.new()
		hint.text="Window size is controlled by the editor. Run in a separate window to change it."
		rows.add_child(hint)
	if not return_to_pause: button("Reset All Data…",confirm_reset)
	button("Back",func():
		if return_to_pause: resume()
		else: menu())

func flat(color: Color,border: Color=Color.TRANSPARENT,width: int=0) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.content_margin_left=18
	style.content_margin_right=18
	style.content_margin_top=9
	style.content_margin_bottom=9
	return style
func style_button(node: Button) -> void:
	node.add_theme_stylebox_override("normal",flat(Color("152735"),Color("31525b"),1))
	node.add_theme_stylebox_override("hover",flat(Color("21434e"),Color("68d2cc"),1))
	node.add_theme_stylebox_override("pressed",flat(Color("31555b"),Color("e3c48b"),2))
	node.add_theme_stylebox_override("focus",flat(Color.TRANSPARENT,Color("f1d59a"),2))
	node.add_theme_stylebox_override("disabled",flat(Color("171d29"),Color("2b303c"),1))

func character_details(id: String) -> String:
	var d: Resource=catalog.get_def(id)
	var bonus: String={"lyra":"+10% XP","brann":"+1 armor / -5% cooldown","noctis":"+15% critical damage / +10% luck","eira":"+15% radius / +10% projectile speed"}[id]
	return "%s · %d HP · %d speed\n%s · %s" % [d.display_name,d.values.hp,roundi(d.values.speed*preload("res://resources/pacing.tres").values.player_speed),catalog.get_def(d.values.weapon).display_name,bonus]
func character_overview() -> void:
	state="MENU"
	box("CHARACTERS","Your heroes. Start a run through New Run in the main menu.")
	for id in catalog.catalogs.character:
		var d: Resource=catalog.get_def(id)
		label(character_details(id) if id in save.data.unlocked_characters else d.display_name,20)
	button("Back",menu)
func pause_recipe_text() -> String:
	var lines: Array[String]=[]
	var unknown: int=0
	for recipe in catalog.catalogs.evolution.values():
		var relevant: bool=model.weapons.has(recipe.id)
		for base in recipe.values.bases:
			if model.weapons.has(base): relevant=true
		if not relevant: continue
		if save.discovered(recipe.id,"evolution"):
			lines.append(recipe.display_name+": "+recipe.description)
		else: unknown+=1
	if unknown>0:
		lines.append("Your current weapons connect to %d undiscovered evolution path%s.\nExperiment with equipment to uncover them." % [unknown,"s" if unknown!=1 else ""])
	if lines.is_empty(): lines.append("No evolution paths for your current weapons.")
	return "\n".join(lines)
func confirm_reset() -> void:
	if return_to_pause: return
	state="RESET_CONFIRM"
	box("RESET ALL DATA?","This permanently clears gold, meta upgrades, unlocks, discoveries,\nrecords, achievements and settings. This cannot be undone.")
	var cancel:=button("Cancel",func(): state="MENU"; settings())
	button("Reset Everything",reset_all_progress)
	focus_button.call_deferred(cancel)
func reset_all_progress() -> void:
	if state!="RESET_CONFIRM": return
	if not save.reset_all():
		box("RESET FAILED",save.warning)
		button("Back",func(): state="MENU"; settings())
		return
	events.clear()
	selected_hero="lyra"
	selected_stage="mist"
	selected_fast=false
	selected_curse=0
	banishing=false
	return_to_pause=false
	# Discard session state so an old result cannot restore pre-reset gold/unlocks.
	model=null
	menu()
	apply_settings()
