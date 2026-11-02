extends RefCounted
const PATHS: Array[String]=["Constellation of Comets","Constellation of the Veil","Constellation of Fractures"]
const NODES: Dictionary={
	"comet_spark":{"name":"Comet Spark","path":0,"rank":1,"effect":"Start movement speed +1%."},
	"gathering_tail":{"name":"Gathering Tail","path":0,"rank":2,"effect":"Magnet radius +6 px."},
	"swift_orbit":{"name":"Swift Orbit","path":0,"rank":3,"effect":"Projectile speed +3%."},
	"astral_insight":{"name":"Astral Insight","path":0,"rank":4,"effect":"XP Growth +2%; rift XP bypasses Growth."},
	"rush_of_stars":{"name":"Rush of Stars","path":0,"rank":5,"effect":"Boss kills grant +2% movement for 20 run seconds. Refreshes without stacking."},
	"far_traveler":{"name":"Far Traveler","path":0,"rank":6,"effect":"Magnet radius +6 px and movement +1%."},
	"veil_seed":{"name":"Veil Seed","path":1,"rank":1,"effect":"Maximum HP +3."},
	"quiet_pulse":{"name":"Quiet Pulse","path":1,"rank":2,"effect":"Regenerate 0.05 HP per second."},
	"guarded_orbit":{"name":"Guarded Orbit","path":1,"rank":3,"effect":"Take 3% less damage from boss projectiles."},
	"second_breath":{"name":"Second Breath","path":1,"rank":4,"effect":"Rift stabilization heals an additional 4 HP."},
	"still_heart":{"name":"Still Heart","path":1,"rank":5,"effect":"At each five-minute boundary, heal 2 HP if below 50% HP (six opportunities per run)."},
	"last_star":{"name":"Last Star","path":1,"rank":6,"effect":"Once per run, recover 8 HP when falling below 25% HP, while still alive."},
	"rift_sense":{"name":"Rift Sense","path":2,"rank":1,"effect":"Pause reveals your current instability band and its next threshold."},
	"tainted_treasure":{"name":"Tainted Treasure","path":2,"rank":2,"effect":"Elite gold +5% while instability is at least 50."},
	"hunters_star":{"name":"Hunter's Star","path":2,"rank":3,"effect":"Deal 3% more direct damage to elites only."},
	"clear_horizon":{"name":"Clear Horizon","path":2,"rank":4,"effect":"Rift stabilization removes an additional 3 instability."},
	"risk_seeker":{"name":"Risk Seeker","path":2,"rank":5,"effect":"Overcharging grants 5% more of its one-time XP reward."},
	"fracture_mastery":{"name":"Fracture Mastery","path":2,"rank":6,"effect":"Deal 3% more direct damage to bosses while instability is at least 75."}}
static func predecessor(id: String) -> String:
	if not NODES.has(id) or NODES[id].rank==1: return ""
	for other in NODES:
		if NODES[other].path==NODES[id].path and NODES[other].rank==NODES[id].rank-1: return other
	return ""
static func reward(model: RefCounted,won: bool) -> int:
	return mini(8,mini(3,model.bosses)+(3 if won and model.time>=1800 else 0)+(1 if model.time>=1200 else 0)+(1 if model.rift_state.peak>=75 else 0))
static func validate() -> Array[String]:
	var errors: Array[String]=[]
	var positions: Dictionary={}
	for id in NODES:
		var d: Dictionary=NODES[id]
		var key: String=str(d.path)+":"+str(d.rank)
		if d.path<0 or d.path>2 or d.rank<1 or d.rank>6 or positions.has(key) or d.name.is_empty() or d.effect.is_empty(): errors.append("Invalid constellation "+id)
		positions[key]=true
	if positions.size()!=18: errors.append("Expected eighteen constellation nodes")
	return errors
