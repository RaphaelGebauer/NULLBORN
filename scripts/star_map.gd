extends Control
const Stars=preload("res://scripts/data/constellations.gd")
const COLORS: Array[Color]=[Color("7ddccf"),Color("aba0e9"),Color("e9b97b")]
var save: RefCounted
var nodes: Dictionary={}
var selected: String="comet_spark"
var detail: Label
var purchase: Button
var wallet: Label
var canvas: Control
var map_scale: float=1
func _ready() -> void:
	map_scale=minf(1,(get_viewport_rect().size.x-40)/1100)
	custom_minimum_size=Vector2(1100,520)*map_scale
	canvas=Control.new()
	canvas.size=Vector2(1100,520)
	canvas.scale=Vector2.ONE*map_scale
	add_child(canvas)
	wallet=Label.new()
	wallet.position=Vector2(15,0)
	canvas.add_child(wallet)
	for path in range(3):
		var heading:=Label.new()
		heading.text=Stars.PATHS[path].trim_prefix("Constellation of ")
		heading.position=Vector2(50+path*365,28)
		heading.modulate=COLORS[path]
		heading.add_theme_font_size_override("font_size",23)
		canvas.add_child(heading)
	for id in Stars.NODES:
		var d: Dictionary=Stars.NODES[id]
		var node:=Button.new()
		node.position=Vector2(20+d.path*365+(25 if d.rank%2==0 else 0),60+(d.rank-1)*58)
		node.size=Vector2(295,47)
		node.add_theme_font_size_override("font_size",17)
		node.tooltip_text=description(id)
		node.pressed.connect(select.bind(id))
		canvas.add_child(node)
		nodes[id]=node
	detail=Label.new()
	detail.position=Vector2(20,420)
	detail.size=Vector2(790,98)
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_font_size_override("font_size",17)
	canvas.add_child(detail)
	purchase=Button.new()
	purchase.position=Vector2(835,448)
	purchase.size=Vector2(240,58)
	purchase.add_theme_font_size_override("font_size",20)
	var purchase_style:=StyleBoxFlat.new()
	purchase_style.bg_color=Color("1c3845")
	purchase_style.border_color=Color("e9d09c")
	purchase_style.set_border_width_all(2)
	purchase_style.set_corner_radius_all(8)
	purchase.add_theme_stylebox_override("normal",purchase_style)
	purchase.add_theme_stylebox_override("focus",purchase_style)
	purchase.pressed.connect(buy_selected)
	canvas.add_child(purchase)
	for id in nodes:
		var d: Dictionary=Stars.NODES[id]
		for other in nodes:
			var o: Dictionary=Stars.NODES[other]
			if o.path==d.path and o.rank==d.rank-1: nodes[id].focus_neighbor_top=nodes[id].get_path_to(nodes[other])
			if o.path==d.path and o.rank==d.rank+1: nodes[id].focus_neighbor_bottom=nodes[id].get_path_to(nodes[other])
			if o.rank==d.rank and o.path==d.path-1: nodes[id].focus_neighbor_left=nodes[id].get_path_to(nodes[other])
			if o.rank==d.rank and o.path==d.path+1: nodes[id].focus_neighbor_right=nodes[id].get_path_to(nodes[other])
		if d.rank==6: nodes[id].focus_neighbor_bottom=nodes[id].get_path_to(purchase)
	refresh()
	focus_selected.call_deferred()
func description(id: String) -> String:
	var d: Dictionary=Stars.NODES[id]
	var previous: String=Stars.predecessor(id)
	var lines: Array[String]=["%s · %d Starlight" % [d.name,d.rank],d.effect]
	if not previous.is_empty(): lines.append("Requires: "+Stars.NODES[previous].name)
	var reason: String=save.star_purchase_error(id)
	if not reason.is_empty() and not reason.begins_with("Requires:"): lines.append(reason)
	return "\n".join(lines)
func select(id: String) -> void:
	selected=id
	if is_instance_valid(detail):
		detail.text=description(id)
		purchase.text="Unlocked" if id in save.data.constellation_nodes else "Unlock · %d Starlight" % Stars.NODES[id].rank
		purchase.disabled=id in save.data.constellation_nodes
		purchase.tooltip_text=description(id)
		for other in nodes: style_node(other)
func style_node(id: String) -> void:
	var color: Color=COLORS[Stars.NODES[id].path]
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172c3b")
	style.border_color=color if id==selected else color.darkened(.45)
	style.set_border_width_all(3 if id==selected else 1)
	style.set_corner_radius_all(20)
	nodes[id].add_theme_stylebox_override("normal",style)
	var hover: StyleBoxFlat=style.duplicate()
	hover.bg_color=style.bg_color.lightened(.08)
	nodes[id].add_theme_stylebox_override("hover",hover)
	nodes[id].add_theme_stylebox_override("pressed",hover)
	# Focus overlays normal/hover: keep it distinct from the persistent outer ring.
	var focused:=StyleBoxFlat.new()
	focused.bg_color=Color.TRANSPARENT
	focused.border_color=color.darkened(.2)
	focused.set_border_width_all(1)
	focused.set_corner_radius_all(16)
	focused.expand_margin_left=-5
	focused.expand_margin_right=-5
	focused.expand_margin_top=-5
	focused.expand_margin_bottom=-5
	nodes[id].add_theme_stylebox_override("focus",focused)
func refresh() -> void:
	wallet.text="%d Starlight · %d / 18 unlocked" % [save.data.starlight,save.data.constellation_nodes.size()]
	for id in nodes:
		var d: Dictionary=Stars.NODES[id]
		nodes[id].text=("✦ " if id in save.data.constellation_nodes else "◇ ")+d.name+" · "+str(d.rank)
		# Modulate text only, so locked selections keep their full-color outline.
		nodes[id].add_theme_color_override("font_color",COLORS[d.path] if id in save.data.constellation_nodes else Color.WHITE if save.star_available(id) else Color(.6,.65,.72))
		nodes[id].tooltip_text=description(id)
	select(selected)
	queue_redraw()
func buy_selected() -> void:
	var reason: String=save.star_purchase_error(selected)
	if not reason.is_empty():
		detail.text=description(selected)
		return
	if save.buy_star(selected): refresh()
	else:
		# Prerequisite/ownership/funds are already shown in the inspector.
		detail.text=description(selected)
		if save.warning!=save.star_purchase_error(selected): detail.text+="\n"+save.warning
func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE*map_scale)
	for i in range(50): draw_circle(Vector2(fposmod(i*173.7,1090),fposmod(i*i*31.2,480)),1,Color(.6,.8,.9,.2))
	for id in nodes:
		var previous: String=Stars.predecessor(id)
		if previous.is_empty(): continue
		var start: Vector2=nodes[previous].position+nodes[previous].size*.5
		var end: Vector2=nodes[id].position+nodes[id].size*.5
		var color: Color=COLORS[Stars.NODES[id].path]
		draw_line(start,end,color if id in save.data.constellation_nodes else color.darkened(.65),3)
		draw_circle((start+end)*.5,4,color)

func focus_selected() -> void:
	if is_inside_tree() and nodes.has(selected): nodes[selected].grab_focus()
