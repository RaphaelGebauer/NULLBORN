extends CharacterBody2D
var speed: float = 220.0
var facing := Vector2.RIGHT
var invulnerable: float = 0.0
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
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 0.1: facing = direction.normalized()
	velocity = direction * speed
	move_and_slide()
	invulnerable = maxf(0, invulnerable - delta)
	queue_redraw()
func _draw() -> void:
	draw_circle(Vector2(0,8), 16, Color(0,0,0,0.4))
	var color := Color("8df5eb")
	if invulnerable > 0 and int(invulnerable * 18) % 2 == 0: color = Color.WHITE
	draw_colored_polygon(PackedVector2Array([Vector2(0,-21),Vector2(14,12),Vector2(0,7),Vector2(-14,12)]),color)
	draw_circle(facing * 9, 4, Color("fff2b0"))
