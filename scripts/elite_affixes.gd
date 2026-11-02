extends RefCounted
# Affix data is independent of the ordinary enemy catalog and its generated resources.
const DEFINITIONS: Dictionary={
	"armored":{"name":"Armored","reduction":.2},
	"swift":{"name":"Swift","speed":1.18,"cap":300.0},
	"volatile":{"name":"Volatile","delay":.75,"radius":85.0,"damage":14.0},
	"vampiric":{"name":"Vampiric","healing":.05,"cooldown":3.0},
	"blinking":{"name":"Blinking","cooldown":7.0,"warning":.3,"min_distance":100.0,"max_distance":150.0},
	"hexbound":{"name":"Hexbound","cooldown":6.0,"speed":115.0},
	"regenerating":{"name":"Regenerating","healing":.0035,"fire_lock":3.0}}
var world: Node2D
var next_spawn: float=300
func prepare(e: Dictionary) -> void:
	e.elite=false
	e.affixes=[]
	e.elite_state={"hex":6.0,"blink":7.0,"warning":0.0,"blink_target":Vector2.ZERO,"vampiric_ready":0.0,"fire_until":0.0}
func active_count() -> int:
	var total: int=0
	for e in world.enemies:
		if e.hp>0 and e.elite: total+=1
	return total
func cap() -> int:
	return 3 if world.model.instability>=75 else 2
func promote(e: Dictionary,requested: Array=[]) -> bool:
	if e.is_empty() or e.boss or e.child or e.kind=="splitter" or e.elite or world.model.time<300 or active_count()>=cap(): return false
	var m: int=mini(29,int(world.model.time/60))
	var wave: Dictionary=world.model.registry.get_def("wave_%02d"%m).values.weights
	if not wave.has(e.kind): return false
	var chosen: Array=requested.duplicate()
	if chosen.is_empty():
		var count: int=1
		if m>=15 and world.model.instability>=75 and world.model.rng.randf()<.55: count=2
		if m>=25 and world.model.instability>=90 and world.model.rng.randf()<.4: count=3
		var pool: Array=DEFINITIONS.keys()
		while chosen.size()<count:
			var id: String=pool.pop_at(world.model.rng.randi_range(0,pool.size()-1))
			chosen.append(id)
			if id=="vampiric": pool.erase("regenerating")
			if id=="regenerating": pool.erase("vampiric")
	if chosen.size()>3: return false
	var unique: Dictionary={}
	for id in chosen:
		if not DEFINITIONS.has(id) or unique.has(id): return false
		unique[id]=true
	if chosen.has("vampiric") and chosen.has("regenerating"): return false
	e.elite=true
	e.affixes=chosen
	e.max_hp*=minf(3.5,2.5+.25*(chosen.size()-1))
	e.hp=e.max_hp
	e.damage*=minf(1.35,1.15+.05*(chosen.size()-1))
	e.speed*=1.06
	e.xp*=2
	if chosen.has("swift"): e.speed=minf(DEFINITIONS.swift.cap,e.speed*DEFINITIONS.swift.speed)
	for id in chosen: world.model.affixes_seen[id]=world.model.affixes_seen.get(id,0)+1
	return true
func director() -> void:
	if world.model.time<next_spawn: return
	var m: int=mini(29,int(world.model.time/60))
	var interval: float=world.model.rng.randf_range(45,65) if m>=25 else world.model.rng.randf_range(55,75) if m>=15 else world.model.rng.randf_range(70,90)
	if world.model.instability>=50: interval*=.92
	next_spawn=world.model.time+interval
	if world.model.time<300 or active_count()>=cap() or world.enemies.size()>=mini(420,55+12*m): return
	var kinds: Array=world.model.registry.get_def("wave_%02d"%m).values.weights.keys().filter(func(id):return id!="splitter")
	var kind: String=kinds[world.model.rng.randi_range(0,kinds.size()-1)]
	var e: Dictionary=world.spawn_enemy(kind)
	promote(e)
func update(e: Dictionary,delta: float) -> void:
	if not e.elite or e.hp<=0: return
	var s: Dictionary=e.elite_state
	if e.affixes.has("regenerating") and e.age>=s.fire_until:
		e.hp=minf(e.max_hp,e.hp+e.max_hp*DEFINITIONS.regenerating.healing*delta)
	if e.affixes.has("hexbound"):
		s.hex-=delta
		if s.hex<=0:
			s.hex=DEFINITIONS.hexbound.cooldown
			world.projectile(e.pos,e.pos.direction_to(world.player.position)*DEFINITIONS.hexbound.speed,{"damage":e.damage*.7,"elite":true},"elite_hex",0,true)
	if e.affixes.has("blinking"):
		if s.warning>0:
			s.warning=maxf(0,s.warning-delta)
			if s.warning<=0 and s.blink_target.distance_to(world.player.position)>90:
				e.pos=s.blink_target
			return
		s.blink-=delta
		if s.blink<=0:
			s.blink=DEFINITIONS.blinking.cooldown
			var side: Vector2=e.pos.direction_to(world.player.position).orthogonal()
			if world.model.rng.randf()<.5: side=-side
			var target: Vector2=e.pos+side*world.model.rng.randf_range(100,150)
			if target.distance_to(world.player.position)>90:
				s.blink_target=target
				s.warning=DEFINITIONS.blinking.warning
func hit(e: Dictionary,source: String,values: Dictionary) -> void:
	if not e.elite: return
	if "fire" in world.model.registry.elements_for_weapon(source) or values.get("burn",0)>0 or e.statuses.has("burn"):
		e.elite_state.fire_until=e.age+DEFINITIONS.regenerating.fire_lock
func contact(e: Dictionary,succeeded: bool) -> void:
	if succeeded and e.elite and e.affixes.has("vampiric") and e.age>=e.elite_state.vampiric_ready:
		e.hp=minf(e.max_hp,e.hp+e.max_hp*DEFINITIONS.vampiric.healing)
		e.elite_state.vampiric_ready=e.age+DEFINITIONS.vampiric.cooldown
func death(e: Dictionary) -> void:
	if not e.elite: return
	world.model.elite_kills+=1
	world.model.rift_state.change(.5)
	world.drop(e.pos+Vector2(18,0),roundi(45*(1+world.model.rift_state.modifiers().reward_gold)),"gold")
	if world.model.rng.randf()<.15: world.drop(e.pos,1,"small_heal")
	if e.affixes.has("volatile"):
		# Snapshot numbers/position only; never retain the pooled enemy dictionary.
		world.hazard(e.pos,DEFINITIONS.volatile.radius,DEFINITIONS.volatile.delay,DEFINITIONS.volatile.damage*(1+.035*e.spawn_minute))
