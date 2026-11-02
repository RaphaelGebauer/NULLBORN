extends RefCounted
const TAGS: Dictionary={
	"ash_bow":["fire"],"sun_beam":["fire"],"meteor_rain":["fire"],
	"frost_shard":["frost"],"moon_blade":["frost"],
	"lightning_call":["storm"],"spark_orbit":["storm"],"storm_bomb":["storm"],
	"thorn_halo":["toxin"],"soul_well":["void"],"shadow_fan":["void"],
	"gravity_mine":["void"],"reaper_gaze":["void"],"arcane_needle":[],"prism_disc":[]}
static func for_weapon(id: String, registry: RefCounted) -> Array[String]:
	var result: Array[String]=[]
	if registry.catalogs.evolution.has(id):
		for base in registry.catalogs.evolution[id].values.bases:
			for tag in for_weapon(base,registry):
				if not tag in result: result.append(tag)
	else:
		for tag in TAGS.get(id,[]): result.append(tag)
	result.sort()
	return result
