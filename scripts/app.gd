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
	button("Neues Spiel",start_run)
	button("Beenden",func(): get_tree().quit())
func start_run() -> void:
	model=Model.new()
	events.clear()
	model.modal_requested.connect(func(kind): events.append(kind))
	model.ended.connect(result)
	world=World.new()
	world.model=model
	world.process_mode=Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	resume()
func resume() -> void:
	state="RUNNING"
	clear_ui()
	hud=Label.new()
	hud.position=Vector2(20,15)
	hud.add_theme_font_size_override("font_size",22)
	ui.add_child(hud)
	get_tree().paused=false
func _process(_delta: float) -> void:
	if state=="RUNNING":
		hud.text="HP %d/%d   |   LV %d   XP %d/%d   |   %02d:%02d   |   %d Kills   |   %d Gold\nWASD / Stick: Bewegung     Esc: Pause" % [model.hp,model.max_hp,model.level,model.xp,model.required_xp(),int(model.time)/60,int(model.time)%60,model.kills,model.gold]
		if not events.is_empty(): show_event()
func show_event() -> void:
	state=events.pop_front()
	get_tree().paused=true
	cards=model.offers()
	box("STERNENAUFSTIEG · Level %d" % model.level,"Wähle eine Verstärkung. Die Welt wartet.")
	for i in range(3): button("%d  ·  %s" % [i+1,cards[i]],choose.bind(i))
func choose(index: int) -> void:
	if state!="LEVELUP": return
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
			box("PAUSE")
			button("Weiter",resume)
			button("Zum Menü",menu)
	if event is InputEventKey and event.pressed and not event.echo and state=="LEVELUP":
		if event.keycode in [KEY_1,KEY_2,KEY_3]: choose(event.keycode-KEY_1)

func focus_button(node: Button) -> void:
	if is_instance_valid(node) and node.is_inside_tree(): node.grab_focus()
