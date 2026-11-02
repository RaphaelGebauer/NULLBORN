extends RefCounted
const SCHEDULE: Array[float]=[360.0,720.0,1080.0,1440.0]
const LIFETIME: float=90
const INTERACTION_RADIUS: float=90
var world: Node2D
var slots_used: int=0
var node: Dictionary={}
var pending_slot: int=0
var pending_expires: float=0
var retry_at: float=0
func update() -> void:
	var time: float=world.model.time
	if not node.is_empty() and time>=node.expires: node={}
	while slots_used<SCHEDULE.size() and time>=SCHEDULE[slots_used]:
		pending_expires=SCHEDULE[slots_used]+LIFETIME
		slots_used+=1
		pending_slot=slots_used if time<pending_expires else 0
		retry_at=0
	if pending_slot==0 or time>=pending_expires or time<retry_at: return
	# A crowded spawn ring retries within this slot's lifetime, never backfills later.
	retry_at=time+1
	for i in range(24):
		var angle: float=world.model.rng.randf()*TAU
		var pos: Vector2=world.player.position+Vector2.RIGHT.rotated(angle)*world.model.rng.randf_range(150,260)
		if world.enemies.any(func(e):return e.hp>0 and e.pos.distance_to(pos)<e.radius+45): continue
		if world.hazards.any(func(h):return h.pos.distance_to(pos)<h.radius+35): continue
		node={"slot":pending_slot,"pos":pos,"expires":pending_expires,"pending":false}
		pending_slot=0
		break
func interact() -> bool:
	if node.is_empty() or node.pending or world.model.time>=node.expires or node.pos.distance_to(world.player.position)>INTERACTION_RADIUS: return false
	node.pending=true
	world.model.modal_requested.emit("RIFT")
	return true
func choose(overcharge: bool) -> bool:
	if node.is_empty() or not node.pending or world.model.time>=node.expires: return false
	# Clear first: XP can enqueue another modal synchronously.
	node={}
	if overcharge:
		world.model.rifts_overcharged+=1
		world.model.rift_state.change(20)
		world.model.gold+=roundi(120*(1+world.model.time/1800))
		world.model.add_xp(world.model.required_xp()*.35*(1.05 if world.model.has_star("risk_seeker") else 1),false)
	else:
		world.model.rifts_stabilized+=1
		world.model.rift_state.change(-23 if world.model.has_star("clear_horizon") else -20)
		world.model.heal(world.model.max_hp*.1+(4 if world.model.has_star("second_breath") else 0))
	return true
