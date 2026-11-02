extends RefCounted
const CELL := 96.0
var cells: Dictionary = {}
func rebuild(enemies: Array) -> void:
	cells.clear()
	for e in enemies:
		if e.hp <= 0: continue
		var key := Vector2i(floor(e.pos.x / CELL), floor(e.pos.y / CELL))
		if not cells.has(key): cells[key] = []
		cells[key].append(e)
func query(center: Vector2, radius: float) -> Array:
	var found: Array = []
	var lo := Vector2i(floor((center.x-radius)/CELL),floor((center.y-radius)/CELL))
	var hi := Vector2i(floor((center.x+radius)/CELL),floor((center.y+radius)/CELL))
	for x in range(lo.x,hi.x+1):
		for y in range(lo.y,hi.y+1):
			for e in cells.get(Vector2i(x,y),[]):
				if e.hp > 0 and e.pos.distance_squared_to(center) <= pow(radius+e.radius,2): found.append(e)
	return found
