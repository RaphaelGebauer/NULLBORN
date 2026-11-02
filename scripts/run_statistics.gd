extends RefCounted
# Fixed-size second buckets; no hit history or enemy references retained.
var damage_by_source: Dictionary={}
var total_damage: float=0
var damage_taken: float=0
var total_healing: float=0
var critical_hits: int=0
var highest_hit: float=0
var highest_ten_second_dps: float=0
var bucket_seconds: PackedInt64Array=PackedInt64Array()
var bucket_damage: PackedFloat64Array=PackedFloat64Array()
func _init() -> void:
	bucket_seconds.resize(11)
	bucket_seconds.fill(-100)
	bucket_damage.resize(11)
func record_damage(source: String, damage: float, remaining_hp: float, critical: bool, game_time: float) -> float:
	var actual: float=clampf(damage,0,maxf(0,remaining_hp))
	if actual<=0: return 0
	var key: String=source if not source.is_empty() else "Unattributed"
	damage_by_source[key]=damage_by_source.get(key,0.0)+actual
	total_damage+=actual
	highest_hit=maxf(highest_hit,actual)
	if critical: critical_hits+=1
	var second: int=int(floor(game_time))
	var slot: int=posmod(second,11)
	if bucket_seconds[slot]!=second:
		bucket_seconds[slot]=second
		bucket_damage[slot]=0
	bucket_damage[slot]+=actual
	var sum: float=0
	for i in range(11):
		if bucket_seconds[i]>second-10 and bucket_seconds[i]<=second: sum+=bucket_damage[i]
	highest_ten_second_dps=maxf(highest_ten_second_dps,sum/10.0)
	return actual
