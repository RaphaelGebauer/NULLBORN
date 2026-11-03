extends CharacterBody2D
var speed: float = 165.0
var facing := Vector2.RIGHT
var tint: Color=Color("8df5eb")
var shape_id: int=0
var reduce_flash: bool=false
var invulnerable: float = 0.0
var hit_flash: float=0
var slow_left: float=0
func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13
	shape.shape = circle
	add_child(shape)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 10
	add_child(camera)
func _physics_process(delta: float) -> void:
	hit_flash=maxf(0,hit_flash-delta)
	slow_left=maxf(0,slow_left-delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 0.1: facing = direction.normalized()
	velocity = direction * speed
	move_and_slide()
	invulnerable = maxf(0, invulnerable - delta)
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2(0,8), 16, Color(0,0,0,0.4))
	var color: Color=tint
	if not reduce_flash and hit_flash>0: color=color.lerp(Color("d7e0db"),.3*hit_flash/.07)
	draw_set_transform(Vector2.ZERO,facing.angle()+PI/2)
	draw_colored_polygon(PackedVector2Array([Vector2(0,-21),Vector2(14,12),Vector2(0,7),Vector2(-14,12)]),color)
	if shape_id==1: draw_rect(Rect2(Vector2(-17,-5),Vector2(34,12)),color.darkened(.15))
	if shape_id==2: draw_arc(Vector2(0,-5),19,-PI,0,16,color,3)
	if shape_id==3:
		for i in range(4): draw_line(Vector2.ZERO,Vector2.RIGHT.rotated(TAU*i/4)*20,Color("ccecff"),2)
