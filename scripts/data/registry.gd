extends RefCounted
var catalogs: Dictionary = {}
var errors: Array[String] = []
var reaction_definitions: Array=preload("res://scripts/data/element_reaction_definitions.gd").DEFINITIONS
var affix_definitions: Dictionary=preload("res://scripts/data/elite_affix_definitions.gd").DEFINITIONS
func _init() -> void:
	var ids: Dictionary={}
	errors.append_array(preload("res://scripts/data/constellations.gd").validate())
	if reaction_definitions.size()!=4: errors.append("Expected four elemental reactions")
	for reaction in reaction_definitions:
		if reaction.elements.size()!=2 or reaction.elements[0]==reaction.elements[1] or reaction.name.is_empty(): errors.append("Invalid reaction "+reaction.id)
	if affix_definitions.size()!=7: errors.append("Expected seven elite affixes")
	for id in affix_definitions:
		if affix_definitions[id].get("name", "").is_empty() or affix_definitions[id].size()<2: errors.append("Invalid elite affix "+id)
	for kind in ["weapon","passive","enemy","character","wave","evolution","rune","stage","mutation"]:
		var catalog: Dictionary = {}
		var path: String = "res://resources/"+("enemies" if kind=="enemy" else kind+"s")+"/"
		var directory := DirAccess.open(path)
		if directory == null:
			errors.append("Missing catalog: "+path)
			continue
		var files := directory.get_files()
		files.sort()
		for file in files:
			if not file.ends_with(".tres"): continue
			var definition: Resource = load(path+file)
			if definition == null or definition.id.is_empty():
				errors.append("Invalid definition "+file)
				continue
			if ids.has(definition.id): errors.append("Duplicate ID "+definition.id)
			ids[definition.id]=true
			if definition.weight <= 0 or definition.description.is_empty(): errors.append("Invalid values "+file)
			catalog[definition.id]=definition
		catalogs[kind]=catalog
	for recipe in catalogs.get("evolution",{}).values():
		for base in recipe.values.bases:
			if not catalogs.weapon.has(base): errors.append("Invalid evolution base "+base)
		if not catalogs.passive.has(recipe.values.passive): errors.append("Invalid catalyst")
	for weapon in catalogs.get("weapon",{}).values():
		if weapon.upgrades.size()!=7 or weapon.values.damage<=0 or weapon.values.cooldown<=0: errors.append("Invalid weapon "+weapon.id)
	for hero in catalogs.get("character",{}).values():
		if not catalogs.weapon.has(hero.values.weapon) or hero.values.hp<=0 or hero.values.speed<=0: errors.append("Invalid hero "+hero.id)
	for enemy in catalogs.get("enemy",{}).values():
		if enemy.values.hp<=0 or enemy.values.speed<=0 or enemy.values.xp<=0 or enemy.values.damage<=0: errors.append("Invalid enemy "+enemy.id)
	for wave in catalogs.get("wave",{}).values():
		var total: float=0
		for id in wave.values.weights:
			if not catalogs.enemy.has(id) or wave.values.weights[id]<=0: errors.append("Invalid wave "+wave.id)
			total+=wave.values.weights[id]
		if not is_equal_approx(total,100) or wave.values.minute<0 or wave.values.minute>29: errors.append("Invalid wave weights "+wave.id)
		if wave.values.boss!="" and (not catalogs.enemy.has(wave.values.boss) or not catalogs.enemy[wave.values.boss].values.boss): errors.append("Invalid wave boss "+wave.id)
	for id in catalogs.weapon:
		var choices: Array=mutation_choices(id)
		if choices.size()!=3: errors.append("Expected three mutations for "+id)
	for mutation in catalogs.mutation.values():
		if not catalogs.weapon.has(mutation.values.weapon) or not mutation.values.effect in preload("res://scripts/data/mutation_definition.gd").EFFECTS or mutation.values.interval<0 or mutation.values.value==0: errors.append("Invalid mutation "+mutation.id)
func mutation_choices(weapon: String) -> Array:
	return catalogs.get("mutation",{}).values().filter(func(d):return d.values.weapon==weapon)
func elements_for_weapon(id: String) -> Array[String]:
	return preload("res://scripts/data/element_tags.gd").for_weapon(id,self)
func get_def(id: String) -> Resource:
	for catalog in catalogs.values():
		if catalog.has(id): return catalog[id]
	return null
func weapon_values(id: String, level: int) -> Dictionary:
	var definition: Resource=get_def(id)
	if catalogs.evolution.has(id):
		var result := weapon_values(definition.values.bases[0],8)
		result.damage*=1.8
		result.merge(definition.values.changes,true)
		result.evolved=true
		return result
	var result: Dictionary=definition.values.duplicate(true)
	for i in range(clampi(level-1,0,7)):
		for key in definition.upgrades[i].delta:
			result[key]=result.get(key,0)+definition.upgrades[i].delta[key]
	return result
