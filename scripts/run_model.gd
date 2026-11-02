extends RefCounted
signal changed
signal modal_requested(kind: String)
signal ended(victory: bool)
var rng := RandomNumberGenerator.new()
var hp: float = 100
var max_hp: float = 100
var speed: float = 220
var armor: float = 0
var might: float = 1
var cooldown: float = 1
var area: float = 1
var duration: float = 1
var projectile_speed: float = 1
var amount: int = 0
var growth: float = 1.1
var greed: float = 1
var magnet: float = 95
var luck: float = 1
var crit: float = 0.05
var crit_factor: float = 1.5
var projectile_damage: float = 1
var time: float = 0
var level: int = 1
var xp: float = 0
var kills: int = 0
var gold: int = 0
var finished: bool = false
var weapons: Dictionary = {"arcane_needle":1}
var passives: Dictionary = {}
var runes: Array = []
var banned: Array = []
var rerolls: int = 2
var skips: int = 1
var banishes: int = 1
var hero: String = "lyra"
var stage: String = "mist"
var fast: bool = false
var curse: float = 0
var registry: RefCounted
var meta: Dictionary = {}
func _init() -> void:
	rng.seed = 72047
func required_xp() -> int:
	return roundi(8+9*(level-1)+0.2*pow(level-1,2))
func add_xp(value: float, apply_growth: bool = true) -> void:
	xp += value * (growth if apply_growth else 1.0)
	while xp >= required_xp():
		xp -= required_xp()
		level += 1
		modal_requested.emit("LEVELUP")
	changed.emit()
func heal(value: float) -> void:
	hp = minf(max_hp,hp+value)
	changed.emit()
func hurt(value: float) -> void:
	if finished: return
	hp = maxf(0,hp-maxf(1,round(value-armor)))
	changed.emit()
	if hp <= 0: finish(false)
func finish(victory: bool) -> void:
	if finished: return
	finished = true
	ended.emit(victory)
func tick(delta: float) -> void:
	if finished: return
	time = minf(1800,time+delta*(2 if fast else 1))
	if time >= 1800: finish(true)
func legal() -> Array:
	var result: Array = []
	for id in ["arcane_needle","power_core","blood_vial","runner_boots"]:
		var owned: Dictionary = weapons if id == "arcane_needle" else passives
		var cap: int = 8 if owned == weapons else 5
		if owned.get(id,0) < cap and not id in banned: result.append(id)
	return result
func offers() -> Array:
	var pool := legal()
	var result: Array = []
	while not pool.is_empty() and result.size() < 3:
		var index := rng.randi_range(0,pool.size()-1)
		result.append(pool.pop_at(index))
	for id in ["reward_gold","reward_heal","reward_xp"]:
		if result.size() < 3: result.append(id)
	return result
func upgrade(id: String) -> void:
	match id:
		"reward_gold": gold += 25
		"reward_heal":
			if hp < max_hp: heal(30)
			else: gold += 25
		"reward_xp": add_xp(required_xp()*0.1,false)
		_:
			var owned: Dictionary = weapons if id == "arcane_needle" else passives
			owned[id] = owned.get(id,0)+1
			recalculate()
	changed.emit()
func recalculate() -> void:
	var ratio := hp/max_hp
	max_hp = 100*(1+0.15*passives.get("blood_vial",0))
	hp = max_hp*ratio
	speed = 220*(1+0.08*passives.get("runner_boots",0))
	might = 1+0.1*passives.get("power_core",0)
