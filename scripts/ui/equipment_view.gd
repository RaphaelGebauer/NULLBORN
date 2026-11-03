extends VBoxContainer
# Presentation only: inventories, levels and imprints always come from the live Model.
const Report=preload("res://scripts/run_report.gd")
var model: RefCounted
var detailed: bool=false
var weapon_grid: GridContainer
var passive_grid: GridContainer
var rune_grid: GridContainer
func _ready() -> void:
	add_theme_constant_override("separation",8 if detailed else 4)
	model.inventory_changed.connect(refresh)
	model.rune_changed.connect(refresh)
	refresh()
func text_node(text: String,font_size: int,centered: bool=true) -> Label:
	var label:=Label.new()
	label.text=text
	label.add_theme_font_size_override("font_size",font_size)
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	return label
func heading(text: String) -> void:
	var label: Label=text_node(text,22 if detailed else 14)
	label.modulate=Color("f0d5a1")
	add_child(label)
func refresh() -> void:
	if not is_inside_tree(): return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for weapons in [true,false]:
		heading("WEAPONS" if weapons else "PASSIVES")
		var grid:=GridContainer.new()
		grid.columns=3 if detailed else 6
		grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation",8)
		grid.add_theme_constant_override("v_separation",8)
		add_child(grid)
		if weapons: weapon_grid=grid
		else: passive_grid=grid
		for slot in Report.equipment_slots(model,weapons): grid.add_child(slot_card(slot))
	if not detailed:
		heading("RUNES")
		var center:=CenterContainer.new()
		add_child(center)
		rune_grid=GridContainer.new()
		rune_grid.columns=mini(3,maxi(1,model.runes.size()))
		rune_grid.add_theme_constant_override("h_separation",14)
		rune_grid.add_theme_constant_override("v_separation",4)
		center.add_child(rune_grid)
		if model.runes.is_empty(): rune_grid.add_child(text_node("—",14))
		for id in model.runes:
			var rune: Label=text_node(model.title(id),14)
			rune.tooltip_text=model.registry.get_def(id).description
			rune.mouse_filter=Control.MOUSE_FILTER_PASS
			rune_grid.add_child(rune)
func slot_card(slot: Dictionary) -> PanelContainer:
	var card:=PanelContainer.new()
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var columns: int=3 if detailed else 6
	var available: float=minf(1050,get_viewport_rect().size.x-40)
	card.custom_minimum_size=Vector2((available-(columns-1)*8)/columns,76 if detailed else 54)
	card.mouse_filter=Control.MOUSE_FILTER_PASS
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("142630") if not slot.id.is_empty() else Color("101a25")
	style.border_color=Color("42626c") if not slot.id.is_empty() else Color("25333f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left=10
	style.content_margin_right=10
	style.content_margin_top=8 if detailed else 6
	style.content_margin_bottom=8 if detailed else 6
	card.add_theme_stylebox_override("panel",style)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	card.add_child(content)
	if slot.id.is_empty():
		var empty: Label=text_node("◇",20)
		empty.modulate=Color("687885")
		content.add_child(empty)
		return card
	var title: Label=text_node(slot.name,18 if detailed else 14,not detailed)
	# Fixed column widths: long names wrap inside their slot rather than widening the grid.
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(title)
	var level: Label=text_node(slot.level+((" · "+slot.kind) if detailed and not slot.kind.is_empty() else ""),14 if detailed else 12,not detailed)
	level.modulate=Color("86d8cd")
	content.add_child(level)
	card.tooltip_text=slot.name+" · "+slot.level+"\n"+slot.kind+"\n"+slot.description
	if detailed:
		var description: Label=text_node(slot.description,15,false)
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		content.add_child(description)
	return card
