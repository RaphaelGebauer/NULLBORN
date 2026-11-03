extends RefCounted
# Combat seconds share status/mutation time, stop on pause, and never use wall time.
const WINDOW: float=3.0
const COOLDOWN: float=1.5
const EVENTS_PER_SECOND: int=40
const SOURCE: String="Elemental Reactions"
const DEFINITIONS: Array[Dictionary]=preload("res://scripts/data/element_reaction_definitions.gd").DEFINITIONS
var world: Node2D
var cached_tags: Dictionary={}
var budget_second: int=-1
var events_this_second: int=0
var events_total: int=0
var counts: Dictionary={}
var visuals: Array=[]
func prepare(enemy: Dictionary) -> void:
	enemy.element_history={}
	enemy.dot_sources={}
	enemy.reaction_ready_at=0.0
func tags(source: String,values: Dictionary,extra: Array) -> Array:
	if not cached_tags.has(source): cached_tags[source]=world.model.registry.elements_for_weapon(source)
	var result: Array=cached_tags[source].duplicate()
	for status in ["burn","poison","slow","freeze_chance","slow_chance"]:
		if values.get(status,0)<=0: continue
		# Probabilistic status tags are supplied only after their actual successful roll.
		if status.ends_with("chance"): continue
		var element: String="fire" if status=="burn" else "toxin" if status=="poison" else "frost"
		if not element in result: result.append(element)
	for element in extra:
		if not element in result: result.append(element)
	return result
func on_hit(enemy: Dictionary,source: String,damage: float,values: Dictionary,extra: Array=[]) -> void:
	var applied: Array=tags(source,values,extra)
	if applied.is_empty(): return
	var now: float=world.combat.elapsed
	var selected: Dictionary={}
	# Only the previous hit's history is eligible. A fusion's first hit cannot self-react.
	if now>=enemy.reaction_ready_at:
		for definition in DEFINITIONS:
			for i in range(2):
				var current: String=definition.elements[i]
				var previous: String=definition.elements[1-i]
				if current in applied and enemy.element_history.has(previous) and now-enemy.element_history[previous].time<=WINDOW:
					selected=definition
					break
			if not selected.is_empty(): break
	# At most five history entries. No enemy/resource references survive pool reset.
	for element in applied: enemy.element_history[element]={"time":now,"source":source}
	if selected.is_empty(): return
	var second: int=int(floor(now))
	if second!=budget_second:
		budget_second=second
		events_this_second=0
	if events_this_second>=EVENTS_PER_SECOND: return
	events_this_second+=1
	events_total+=1
	counts[selected.id]=counts.get(selected.id,0)+1
	enemy.reaction_ready_at=now+COOLDOWN
	var pos: Vector2=enemy.pos
	if selected.id=="void_shatter" and enemy.hp>0: enemy.statuses.slow=maxf(enemy.statuses.get("slow",0),.35 if enemy.boss else .75)
	var target_factor: float=world.target_star_factor(enemy)
	var bonus: float=selected.bonus
	if bonus>0 and enemy.hp>0: reaction_hit(enemy,damage*bonus,selected.id,source,target_factor)
	var remaining: int=selected.targets-(1 if selected.id=="blightburst" else 0)
	if remaining>0:
		# Bounded spatial query, stable nearest-target ordering; never a scan of all enemies.
		var candidates: Array=world.grid.query(pos,selected.radius).filter(func(e):return e.hp>0 and e.id!=enemy.id and e.pos.distance_squared_to(pos)<=selected.radius*selected.radius)
		candidates.sort_custom(func(a,b):return a.pos.distance_squared_to(pos)<b.pos.distance_squared_to(pos))
		for other in candidates.slice(0,remaining): reaction_hit(other,damage*selected.secondary,selected.id,source,target_factor)
	if visuals.size()<6 and not visuals.any(func(effect):return effect.pos.distance_squared_to(pos)<6400): visuals.append({"pos":pos,"name":selected.name,"life":.45,"radius":18.0})
func reaction_hit(enemy: Dictionary,damage: float,id: String,trigger: String,inherited_target_factor: float=1.0) -> void:
	var values: Dictionary={"reaction":true,"reaction_id":id,"trigger_weapon":trigger}
	if id=="blightburst": values.burn=1
	world.hit(enemy,damage*(.5 if enemy.boss else 1),values,SOURCE,true,Vector2.INF,inherited_target_factor)
func update(delta: float) -> void:
	for effect in visuals: effect.life-=delta
	visuals=visuals.filter(func(effect):return effect.life>0)
static func legend() -> String:
	return "Frost + Storm: Arc Freeze · Fire + Toxin: Blightburst\nFrost + Void: Void Shatter · Storm + Void: Rift Conduction\nCombine elements within 3 s · 1.5 s cooldown per enemy"
