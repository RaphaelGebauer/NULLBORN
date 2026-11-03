extends RefCounted
# Pure immutable definitions, shared by Registry and gameplay.
const DEFINITIONS: Dictionary={
	"armored":{"name":"Armored","reduction":.2},
	"swift":{"name":"Swift","speed":1.18,"cap":300.0},
	"volatile":{"name":"Volatile","delay":.75,"radius":85.0,"damage":14.0},
	"vampiric":{"name":"Vampiric","healing":.05,"cooldown":3.0},
	"blinking":{"name":"Blinking","cooldown":7.0,"warning":.3,"min_distance":100.0,"max_distance":150.0},
	"hexbound":{"name":"Hexbound","cooldown":6.0,"speed":115.0},
	"regenerating":{"name":"Regenerating","healing":.0035,"fire_lock":3.0}}
