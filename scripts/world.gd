extends Node2D
const Hash = preload("res://scripts/spatial_hash.gd")
const Player = preload("res://scripts/player.gd")
var model: RefCounted
var player: CharacterBody2D
var enemies: Array = []
var shots: Array = []
var pickups: Array = []
var grid := Hash.new()
var budget: float = 0
var fire_timer: float = 0
var serial: int = 0
func _ready() -> void:
	player = Player.new()
	add_child(player)
func spawn_enemy(id: String = "wisp", pos: Vector2 = Vector2.INF) -> Dictionary:
	if pos == Vector2.INF:
		var side: int = model.rng.randi_range(0,3)
		var offset := Vector2(model.rng.randf_range(-750,750),model.rng.randf_range(-470,470))
		if side < 2: offset.x = 750 if side == 0 else -750
		else: offset.y = 470 if side == 2 else -470
		pos = player.position+offset
	serial += 1
	var e := {"id":serial,"kind":id,"pos":pos,"hp":14.0 if id == "wisp" else 8.0,"speed":85.0 if id == "wisp" else 150.0,"radius":12.0,"damage":6.0,"xp":1}
	enemies.append(e)
	return e
func _physics_process(delta: float) -> void:
	model.tick(delta)
	if model.finished: return
	player.speed = model.speed
	budget = minf(3,budget+delta*(1.6+model.time/160))
	while budget >= 1 and enemies.size() < 100:
		budget -= 1
		spawn_enemy("wisp" if model.rng.randf()<0.8 else "mite")
	for e in enemies:
		e.pos += e.pos.direction_to(player.position)*e.speed*delta
		if e.pos.distance_to(player.position)<e.radius+13 and player.invulnerable <= 0:
			model.hurt(e.damage)
			player.invulnerable = 0.65
	grid.rebuild(enemies)
	fire_timer -= delta
	if fire_timer <= 0 and not enemies.is_empty():
		var target: Dictionary = enemies[0]
		for e in enemies:
			if e.pos.distance_squared_to(player.position)<target.pos.distance_squared_to(player.position): target=e
		shots.append({"pos":player.position,"velocity":player.position.direction_to(target.pos)*450,"life":3.0,"damage":13*model.might*(1+0.15*(model.weapons.arcane_needle-1))})
		fire_timer=0.85
	for s in shots:
		s.pos += s.velocity*delta
		s.life -= delta
		for e in grid.query(s.pos,6):
			e.hp-=s.damage
			s.life=0
			break
	shots=shots.filter(func(s): return s.life>0)
	for e in enemies:
		if e.hp<=0:
			model.kills+=1
			pickups.append({"pos":e.pos,"value":e.xp})
	enemies=enemies.filter(func(e): return e.hp>0)
	for p in pickups:
		if p.pos.distance_to(player.position)<model.magnet: p.pos=p.pos.move_toward(player.position,500*delta)
		if p.pos.distance_to(player.position)<18:
			model.add_xp(p.value)
			p.value=0
	pickups=pickups.filter(func(p): return p.value>0)
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(player): return
	var origin := Vector2i(player.position/96)
	for x in range(origin.x-9,origin.x+10):
		for y in range(origin.y-6,origin.y+7):
			var pos := Vector2(x,y)*96
			draw_rect(Rect2(pos,Vector2(95,95)),Color(0.035,0.065,0.09))
			if posmod(x*73+y*37,7)==0:
				draw_circle(pos+Vector2(32,54),5,Color("43646b"))
	for p in pickups:
		draw_colored_polygon(PackedVector2Array([p.pos+Vector2(0,-6),p.pos+Vector2(5,0),p.pos+Vector2(0,6),p.pos+Vector2(-5,0)]),Color("56e6dd"))
	for e in enemies:
		draw_circle(e.pos+Vector2(0,5),e.radius+2,Color(0,0,0,0.4))
		draw_circle(e.pos,e.radius,Color("b77bd6") if e.kind=="wisp" else Color("e8ad6b"))
		draw_circle(e.pos+Vector2(-4,-3),2,Color.WHITE)
	for s in shots: draw_line(s.pos-s.velocity.normalized()*12,s.pos,Color("b7ffff"),4)
