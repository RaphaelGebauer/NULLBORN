extends RefCounted
const TRANSITION: float=.6
const DASH_SPEED: float=240
const DASH_DURATION: float=.7
const NULL_LIMIT: int=4
var world: Node2D
func prepare(e: Dictionary) -> void:
	e.boss_hp_phase=1
	e.phase_transitions=0
	e.transition_left=0.0
	e.attack_pattern_step=0
	e.boss_recovery=0.0
	e.dash_state=0
	e.dash_left=0.0
	e.dash_direction=Vector2.ZERO
	e.safe_gap_angle=0.0
	e.safe_gap_degrees=0.0
	e.parent_boss=0
	e.boss_timers={"dash":5.0,"ring":6.0,"stars":7.0,"summon":5.0,"bolts":6.0,"zones":7.0,"storm":6.0}
func update(e: Dictionary,direction: Vector2,delta: float) -> Vector2:
	if e.boss_hp_phase==1 and e.hp<=e.max_hp*.5:
		e.boss_hp_phase=2
		e.phase_transitions+=1
		e.transition_left=TRANSITION
		e.dash_state=0
		e.dash_left=0
		e.boss_recovery=TRANSITION
		world.model.boss_phase_changed.emit(e.kind,2)
	if e.transition_left>0:
		e.transition_left=maxf(0,e.transition_left-delta)
		return Vector2.ZERO
	for id in e.boss_timers: e.boss_timers[id]-=delta
	e.boss_recovery=maxf(0,e.boss_recovery-delta)
	match e.kind:
		"astral_guardian": return guardian(e,direction,delta)
		"void_queen": return queen(e,direction)
		"storm_core": return storm(e,direction)
	return direction*e.speed
func ring(e: Dictionary,count: int,speed: float,gap_degrees: float,warning: float) -> void:
	var center: float=e.pos.direction_to(world.player.position).angle()
	e.safe_gap_angle=center
	e.safe_gap_degrees=gap_degrees
	add_hazard({"pos":e.pos,"radius":95.0,"delay":warning,"life":warning+.05,"damage":0.0,"fired":false,"preview_only":true,"gap_angle":center,"gap":deg_to_rad(gap_degrees)})
	for i in range(count):
		var angle: float=TAU*i/count
		if absf(wrapf(angle-center,-PI,PI))<deg_to_rad(gap_degrees)*.5: continue
		world.projectile(e.pos,Vector2.RIGHT.rotated(angle)*speed,{"damage":e.damage*.7,"boss":true},"boss_ring",warning,true)
func guardian(e: Dictionary,direction: Vector2,delta: float) -> Vector2:
	if e.dash_state>0:
		e.dash_left=maxf(0,e.dash_left-delta)
		if e.dash_state==1:
			if e.dash_left<=0:
				e.dash_state=2
				e.dash_left=DASH_DURATION
			return Vector2.ZERO
		if e.dash_left>0: return e.dash_direction*DASH_SPEED
		e.dash_state=0
		e.boss_recovery=.7
		return Vector2.ZERO
	if e.boss_recovery>0: return direction*e.speed
	if e.boss_timers.dash<=0:
		e.boss_timers.dash=4.0 if e.boss_hp_phase==2 else 5.0
		e.dash_direction=direction
		e.dash_state=1
		e.dash_left=.9 if e.boss_hp_phase==2 else .8
		return Vector2.ZERO
	if e.boss_hp_phase==2 and e.boss_timers.stars<=0:
		e.boss_timers.stars=7
		var origin: Vector2=world.player.position
		for i in range(3):
			var pos: Vector2=origin+Vector2.RIGHT.rotated(direction.angle()+(i-1)*.9)*110
			world.hazard(pos,65,1.0,e.damage*.8)
		e.boss_recovery=1.5
	elif e.boss_timers.ring<=0:
		e.boss_timers.ring=6
		ring(e,14,130,70,.8)
		e.boss_recovery=1.5
	return direction*e.speed
func safe_summons(e: Dictionary) -> void:
	var children: int=0
	for other in world.enemies:
		if other.hp>0 and other.parent_boss==e.id: children+=1
	for i in range(mini(3,6-children)):
		for attempt in range(12):
			var pos: Vector2=e.pos+Vector2.RIGHT.rotated(world.model.rng.randf()*TAU)*world.model.rng.randf_range(65,110)
			if pos.distance_to(world.player.position)<90: continue
			if world.hazards.any(func(h):return h.get("kind","")=="null_zone" and h.pos.distance_to(pos)<h.radius+15): continue
			var child: Dictionary=world.spawn_enemy("mite",pos,true)
			if not child.is_empty(): child.parent_boss=e.id
			break
func queen(e: Dictionary,direction: Vector2) -> Vector2:
	if e.boss_recovery>0: return direction*e.speed
	if e.boss_timers.summon<=0:
		e.boss_timers.summon=5
		safe_summons(e)
	if e.boss_hp_phase==2 and e.boss_timers.zones<=0:
		e.boss_timers.zones=7
		var active: int=0
		for h in world.hazards:
			if h.get("kind","")=="null_zone": active+=1
		var origin: Vector2=world.player.position
		for i in range(mini(2,NULL_LIMIT-active)):
			var pos: Vector2=origin+direction.orthogonal()*(110 if i==0 else -110)
			add_hazard({"pos":pos,"radius":75.0,"delay":1.0,"life":3.5,"damage":e.damage*.65,"fired":false,"kind":"null_zone","repeat":.8,"tick":0.0,"slow":true,"owner":e.id})
		e.boss_recovery=1.5
	elif e.boss_timers.bolts<=0:
		e.boss_timers.bolts=6
		for sign_value in [-1,1]:
			world.projectile(e.pos,direction.rotated(sign_value*.3)*110,{"damage":e.damage*.65,"boss":true,"curve":sign_value*.22},"queen_bolt",.5,true)
		e.boss_recovery=1
	return direction*e.speed
func storm(e: Dictionary,direction: Vector2) -> Vector2:
	if e.boss_recovery>0 or e.boss_timers.storm>0: return direction*e.speed
	e.boss_timers.storm=6
	if e.attack_pattern_step%2==0:
		ring(e,24 if e.boss_hp_phase==2 else 18,160,60 if e.boss_hp_phase==2 else 50,.8)
	else:
		var center: float=e.pos.direction_to(world.player.position).angle()
		for i in range(3):
			var angle: float=center+PI*.5+i*PI*.5
			add_hazard({"pos":e.pos,"end":e.pos+Vector2.RIGHT.rotated(angle)*650,"radius":12.0,"delay":1.0,"life":1.4,"damage":e.damage*.7,"fired":false})
	e.attack_pattern_step+=1
	e.boss_recovery=2
	return direction*e.speed

func add_hazard(value: Dictionary) -> void:
	if world.hazards.size()<100: world.hazards.append(value)
