extends RefCounted
# Pure text projections of measured events/current model values; never roll offers or tick.
const Stars=preload("res://scripts/data/constellations.gd")
const Save=preload("res://scripts/save_manager.gd")
const BEHAVIORS: Dictionary={"needle":"Aimed projectiles","fan":"Spread of projectiles","radial":"Radial volley","aura":"Pulse around your hero","orbit":"Orbiting close-range hits","lightning":"Targeted strikes and chains","beam":"Sweeping beam","zone":"Persistent area","meteor":"Warned falling strikes","ricochet":"Bouncing disc","mine":"Armed proximity implosion","execution":"Weakest-target execution","bomb":"Timed area explosion","boomerang":"Returning crescent"}
static func source_name(model: RefCounted,id: String) -> String:
	if id=="Elemental Reactions": return id
	var d: Resource=model.registry.get_def(id)
	return d.display_name if d!=null else id.replace("_"," ").capitalize()
static func metrics(model: RefCounted) -> String:
	var s: RefCounted=model.statistics
	var seconds: float=s.combat_seconds
	return "Total Damage Dealt: %.1f · Average DPS: %.1f\nDamage Taken: %.1f · Total Healing: %.1f\nCritical Hits: %d · Highest Critical Hit: %.1f · Highest Single Hit: %.1f\nHighest 10-Second DPS: %.1f\nXP Gained: %.1f · Run Gold: %d · Gold from Pickups: %d\nUpgrades: %d · Mutations: %d · Evolutions: %d · Fusions: %d\nCombat Time: %.1f s" % [s.total_damage,s.total_damage/seconds if seconds>0 else 0,s.damage_taken,s.total_healing,s.critical_hits,s.highest_critical_hit,s.highest_hit,s.highest_ten_second_dps,s.xp_gained,model.gold,s.gold_from_pickups,s.upgrades,s.mutations,s.evolutions,s.fusions,seconds]
static func damage_rows(model: RefCounted) -> Array:
	var s: RefCounted=model.statistics
	var ids: Array=s.damage_by_source.keys()
	ids.sort_custom(func(a,b):return s.damage_by_source[a]>s.damage_by_source[b])
	var rows: Array=[]
	for id in ids:
		var damage: float=s.damage_by_source[id]
		var kind: String=""
		if model.registry.catalogs.weapon.has(id): kind="Base weapon"
		elif model.registry.catalogs.evolution.has(id): kind="Fusion" if model.registry.get_def(id).values.bases.size()>1 else "Evolution"
		else: kind="Reaction" if id=="Elemental Reactions" else "Other source"
		rows.append({"id":id,"name":source_name(model,id),"kind":kind,"damage":damage,"share":100*damage/s.total_damage if s.total_damage>0 else 0,"dps":damage/s.combat_seconds if s.combat_seconds>0 else 0})
	return rows
static func passive_text(model: RefCounted,id: String) -> String:
	var level: int=model.passives[id]
	match id:
		"multiplicity": return "+%d projectiles; +%.0f%% projectile damage" % [model.amount,(model.projectile_damage-1)*100]
		"recovery_moss": return "+%.2f HP/s" % (.25*level)
		"execution_seal": return "+%.0f%% direct damage to targets at or below 35%% HP" % (8*level)
		"frost_thorns": return "Contact retaliation: %d damage · 100 px radius · Slow" % (5*level)
		"momentum_feather": return "+%.1f%% movement (max at 5 run minutes)" % (2*level*minf(5,model.time/60))
	var v: Dictionary=model.registry.get_def(id).values
	var amount: float=v.bonus*level
	return "%+.2f %s" % [amount,v.stat.replace("_"," ")] if v.stat in ["armor","magnet","crit_factor"] else "%+.1f%% %s" % [amount*100,v.stat.replace("_"," ")]
static func equipment_slots(model: RefCounted,weapons: bool) -> Array:
	var slots: Array=[]
	var inventory: Dictionary=model.weapons if weapons else model.passives
	for id in inventory:
		var evolved: bool=model.registry.catalogs.evolution.has(id)
		var fusion: bool=evolved and model.registry.get_def(id).values.bases.size()>1
		var kind: String=("Fusion" if fusion else "Evolved" if evolved else "Base") if weapons else ""
		var description: String=passive_text(model,id) if not weapons else ""
		if weapons:
			var values: Dictionary=model.registry.weapon_values(id,inventory[id])
			description=BEHAVIORS.get(values.behavior,values.behavior.capitalize())
			for imprint in model.weapon_mutations.get(id,[]):
				var mutation: Resource=model.registry.get_def(imprint.id)
				var origin: String="Echo 50%" if imprint.strength<1 else "Primary 100%" if fusion else "Inherited Mutation" if evolved else "Mutation"
				description+="\n%s · %s\n%s" % [origin,mutation.display_name,mutation.description]
		var level: String="Lv %d" % inventory[id] if evolved else "Lv %d / %d" % [inventory[id],8 if weapons else 5]
		slots.append({"id":id,"name":model.title(id),"level":level,"kind":kind,"description":description})
	while slots.size()<6: slots.append({"id":""})
	return slots
static func build_sections(model: RefCounted,world: Node2D=null) -> Array:
	var sections: Array=[]
	var lines: Array[String]=[]
	var h: Dictionary=model.registry.get_def(model.hero).values
	lines=[model.title(model.hero)+" · "+model.title(model.stage),"Base HP %.0f · Base Speed %.2f px/s" % [h.hp,h.speed*model.pacing.values.player_speed]]
	for stat in h.bonuses:
		if stat in ["armor","magnet","crit_factor"]: lines.append("Hero: %+.2f %s" % [h.bonuses[stat],stat.replace("crit_factor","critical multiplier")])
		else: lines.append("Hero: %+.1f%% %s" % [h.bonuses[stat]*100,stat.replace("_"," ")])
	for id in model.meta: lines.append("Star Forge: %s ×%d · %s per rank" % [Save.META[id].name,model.meta[id],Save.META[id].effect])
	for id in model.constellation_nodes:
		if Stars.NODES.has(id): lines.append("Star: "+Stars.NODES[id].name+" · "+Stars.NODES[id].effect)
	sections.append(["Hero & Bonuses","\n".join(lines)])
	lines=[]
	for id in model.runes: lines.append(model.title(id)+" · "+model.registry.get_def(id).description)
	sections.append(["Runes","\n".join(lines) if not lines.is_empty() else "None"])
	var speed: float=model.speed*(.8 if world!=null and world.player.slow_left>0 else 1)
	sections.append(["Current Stats","HP %.2f / %.2f · Armor %.1f · Regeneration %.2f HP/s\nMove Speed %.2f px/s · Might ×%.3f · Cooldown ×%.3f\nArea ×%.3f · Duration ×%.3f · Projectile Speed ×%.3f\nAmount +%d · Projectile Damage ×%.3f · Magnet %.1f px\nGrowth ×%.3f · Greed ×%.3f · Luck ×%.3f\nCrit Chance %.1f%% · Crit Multiplier ×%.3f\nOpening Pace · Enemy Speed ×%.3f · density ×%.3f · projectile speed ×%.3f · attack interval ×%.3f" % [model.hp,model.max_hp,model.armor,model.regeneration,speed,model.might,model.cooldown,model.area,model.duration,model.projectile_speed,model.amount,model.projectile_damage,model.magnet,model.growth,model.greed,model.luck,model.crit*100,model.crit_factor,model.opening_factor("enemy_speed"),model.opening_factor("spawn_rate"),model.opening_factor("projectile_speed"),model.opening_factor("attack_interval")]])
	sections[-1][1]+="\nAttack Interval: ×%.3f (Cooldown × Opening Pace × Resonance)" % (model.cooldown*model.opening_factor("attack_interval")*(.85 if model.resonance>0 else 1))
	lines=[]
	if model.resonance>0: lines.append("Resonance: attack interval ×0.85 · %.2f s" % model.resonance)
	if model.time<model.rush_until: lines.append("Rush of Stars: +2% movement · %.2f run seconds" % (model.rush_until-model.time))
	if model.temporary_luck>0: lines.append("Lantern Luck: +%.2f Luck · This run" % model.temporary_luck)
	if lines.is_empty(): lines.append("None")
	sections.append(["Temporary effects","\n".join(lines)])
	lines=[]
	for id in model.weapons:
		var tags: Array=model.registry.elements_for_weapon(id)
		lines.append(model.title(id)+": "+(", ".join(tags.map(func(tag):return tag.capitalize())) if not tags.is_empty() else "Neutral"))
	lines.append("Mutations and status effects can add elements on hit.")
	lines.append(preload("res://scripts/element_reactions.gd").legend())
	sections.append(["Elements & Reactions","\n".join(lines)])
	return sections
