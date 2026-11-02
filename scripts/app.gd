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
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	setup_input()
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
	var center:=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center)
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
	node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(node)
	return node
func button(text: String, action: Callable) -> Button:
	var node:=Button.new()
	node.text=text
	node.custom_minimum_size.y=52
	node.add_theme_font_size_override("font_size",20)
	node.pressed.connect(action)
	panel.add_child(node)
	if panel.get_child_count()<=3: focus_button.call_deferred(node)
	return node
func menu() -> void:
	get_tree().paused=false
	state="MENU"
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	box("S T E R N E N B R U C H","Überlebe den Riss. Schmiede deinen Stern.")
	button("Neues Spiel",character_select)
	button("Sammlung / Bestiarium",collection)
	button("Beenden",func(): get_tree().quit())
func start_run() -> void:
	model=Model.new()
	model.rng.randomize()
	model.hero=selected_hero
	model.stage=selected_stage
	model.fast=selected_fast
	model.curse=selected_curse
	model.weapons={catalog.get_def(selected_hero).values.weapon:1}
	model.recalculate()
	events.clear()
	model.modal_requested.connect(func(kind): events.append(kind))
	model.ended.connect(result)
	world=preload("res://scenes/game.tscn").instantiate()
	world.model=model
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	events.append("RUNE")
	resume()
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
	ui.add_child(hp_bar)
	xp_bar=ProgressBar.new()
	xp_bar.position=Vector2(340,46)
	xp_bar.size=Vector2(600,18)
	xp_bar.show_percentage=false
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
	for pair in [["Waffen",model.weapons],["Passive",model.passives]]:
		var names: Array=[]
		for id in pair[1]: names.append("◆ %s %d" % [model.title(id),pair[1][id]])
		for i in range(6-pair[1].size()): names.append("◇")
		rows.append(pair[0]+": "+"  ·  ".join(names))
	var names: Array=[]
	for id in model.runes: names.append(model.title(id))
	rows.append("Runen: "+" · ".join(names))
	return "\n".join(rows)
func _process(_delta: float) -> void:
	if state=="RUNNING":
		hud.text="HP %d/%d   |   LV %d   XP %d/%d   |   %02d:%02d   |   %d Kills   |   %d Gold   |   Welle %d" % [model.hp,model.max_hp,model.level,model.xp,model.required_xp(),int(model.time)/60,int(model.time)%60,model.kills,model.gold,mini(30,int(model.time)/60+1)]
		hp_bar.max_value=model.max_hp
		hp_bar.value=model.hp
		xp_bar.max_value=model.required_xp()
		xp_bar.value=model.xp
		build_label.text=build_text()
		boss_label.text=""
		for e in world.enemies:
			if e.boss: boss_label.text+="%s   %d / %d HP\n" % [model.title(e.kind),maxi(0,int(e.hp)),int(e.max_hp)]
		var seconds: int=int(model.time)%60
		if seconds>=50 and int(model.time)/60 in [4,9,14,19,24,28]: boss_label.text+="⚠ Boss-Ankunft in %d Sekunden" % (60-seconds)
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
			box("RUNENSEGEN","Wähle einen dauerhaften Segen für diesen Run. Kein Ausrüstungsslot nötig.")
			for i in range(cards.size()): button("%d · %s\n%s" % [i+1,model.title(cards[i]),catalog.get_def(cards[i]).description],choose_rune.bind(i))
		"CHEST","CHEST_EVOLUTION": open_chest(state=="CHEST_EVOLUTION")
func choose_rune(index: int) -> void:
	if state!="RUNE" or index>=cards.size(): return
	model.add_rune(cards[index])
	resume()
func open_chest(eligible: bool) -> void:
	var evolution: String=model.evolution(eligible)
	var reward: int=model.rng.randi_range(60,140)
	var lines: String=""
	if evolution!="": lines="Neue Evolution!\n"+model.title(evolution)+"\n"+catalog.get_def(evolution).description
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
				lines+="Verstärkt: "+model.title(id)+"\n"
	model.gold+=roundi(reward*model.greed)
	state="CHEST"
	box("STERNENTRUHE",lines+"\n+%d Gold" % roundi(reward*model.greed))
	button("Belohnung annehmen",resume)
func choose(index: int) -> void:
	if state!="LEVELUP": return
	if banishing:
		var next: Array=model.banish(cards[index])
		if next.is_empty(): return
		banishing=false
		cards=next
		redraw_cards()
		return
	model.upgrade(cards[index])
	world.player.invulnerable=maxf(world.player.invulnerable,0.3)
	resume()
func result(victory: bool) -> void:
	state="VICTORY" if victory else "DEFEAT"
	get_tree().paused=true
	box("DER RISS IST GESCHLOSSEN" if victory else "DEIN STERN VERGLÜHT","Level %d · %d Kills · %02d:%02d" % [model.level,model.kills,int(model.time)/60,int(model.time)%60])
	button("Erneut versuchen",func(): menu(); start_run())
	button("Zum Menü",menu)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and state in ["RUNNING","PAUSED"]:
		if state=="PAUSED": resume()
		else:
			state="PAUSED"
			get_tree().paused=true
			box("PAUSE",build_text())
			var recipes: String=""
			for recipe in catalog.catalogs.evolution.values():
				var owned: bool=false
				for base in recipe.values.bases:
					if model.weapons.has(base): owned=true
				if owned: recipes+=recipe.display_name+": "+recipe.description+"\n"
			label(recipes,14)
			button("Weiter",resume)
			button("Run beenden",confirm_end)
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
	box("VERBANNEN: Wähle eine Karte" if banishing else "STERNENAUFSTIEG · Level %d" % model.level,"Wähle eine Verstärkung. Die Welt wartet.")
	for i in range(3): button("%d  ·  %s\n%s" % [i+1,model.title(cards[i]),model.describe(cards[i])],choose.bind(i))
	button("Neu würfeln [R] · %d" % model.rerolls,reroll_cards).disabled=model.rerolls<=0
	button("Überspringen [T] · %d" % model.skips,skip_cards).disabled=model.skips<=0
	button("Verbannen [B] · %d" % model.banishes,toggle_banish).disabled=model.banishes<=0
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
	box("WÄHLE DEINEN STERN","Jeder Held beginnt mit einer eigenen Waffe.")
	for id in catalog.catalogs.character:
		var d: Resource=catalog.get_def(id)
		button("%s · %d HP · %d Tempo\n%s" % [d.display_name,d.values.hp,d.values.speed,catalog.get_def(d.values.weapon).display_name],select_hero.bind(id))
	button("Zurück",menu)
func select_hero(id: String) -> void:
	selected_hero=id
	stage_select()
func stage_select() -> void:
	box("AM RAND DES RISSES","Wähle Arena, Zeitmodus und freiwilligen Fluch.")
	for id in catalog.catalogs.stage:
		button(("◆ " if selected_stage==id else "◇ ")+catalog.get_def(id).display_name,func(): selected_stage=id; stage_select())
	button("Modus: "+("Schnell · 15 Minuten" if selected_fast else "Normal · 30 Minuten"),func(): selected_fast=not selected_fast; stage_select())
	var row:=HBoxContainer.new()
	panel.add_child(row)
	var text:=Label.new()
	text.text="Fluch: +%d %% Gegner / Bonusgold" % roundi(selected_curse*100)
	row.add_child(text)
	var slider:=HSlider.new()
	slider.min_value=0
	slider.max_value=.5
	slider.step=.1
	slider.value=selected_curse
	slider.custom_minimum_size.x=300
	slider.value_changed.connect(func(v): selected_curse=v; text.text="Fluch: +%d %% Gegner / Bonusgold" % roundi(v*100))
	row.add_child(slider)
	button("In den Riss",start_run)
	button("Zurück",character_select)
func collection() -> void:
	box("SAMMLUNG / BESTIARIUM")
	var scroll:=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(900,450)
	panel.add_child(scroll)
	var text:=RichTextLabel.new()
	text.custom_minimum_size=Vector2(850,0)
	text.fit_content=true
	var lines: String=""
	for kind in catalog.catalogs:
		lines+="\n"+{"weapon":"WAFFEN","passive":"PASSIVE","enemy":"BESTIARIUM","character":"HELDEN","wave":"WELLEN","evolution":"REZEPTE","rune":"RUNEN","stage":"ARENEN"}[kind]+"\n"
		for d in catalog.catalogs[kind].values(): lines+=d.display_name+" · "+d.description+"\n"
	text.text=lines
	scroll.add_child(text)
	button("Zurück",menu)
func confirm_end() -> void:
	box("RUN BEENDEN?","Der Run endet als Niederlage. Erhaltenes Gold bleibt erhalten.")
	button("Weiterspielen",resume)
	button("Run abschließen",func(): model.finish(false))
