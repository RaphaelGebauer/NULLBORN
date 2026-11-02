extends RefCounted
signal changed(value: float, band: int)
const THRESHOLDS: Array[float]=[0.0,25.0,50.0,75.0,90.0]
const NAMES: Array[String]=["Dormant","Stirring","Fractured","Unstable","Critical"]
const MODIFIERS: Array[Dictionary]=[
	{"spawn":1.0,"speed":1.0,"contact":1.0,"reward_gold":0.0},
	{"spawn":1.05,"speed":1.03,"contact":1.0,"reward_gold":.1},
	{"spawn":1.12,"speed":1.06,"contact":1.08,"reward_gold":.2},
	{"spawn":1.2,"speed":1.1,"contact":1.12,"reward_gold":.3},
	{"spawn":1.25,"speed":1.12,"contact":1.2,"reward_gold":.4}]
var value: float=0
var peak: float=0
func band() -> int:
	for i in range(THRESHOLDS.size()-1,-1,-1):
		if value>=THRESHOLDS[i]: return i
	return 0
func change(amount: float) -> void:
	if not is_finite(amount): return
	value=clampf(value+amount,0,100)
	peak=maxf(peak,value)
	changed.emit(value,band())
func advance(run_delta: float) -> void:
	change(maxf(0,run_delta)*.03)
func modifiers() -> Dictionary:
	# Callers must not mutate the shared band definitions or accumulate factors.
	return MODIFIERS[band()].duplicate(true)
