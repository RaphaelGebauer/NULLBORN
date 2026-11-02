extends RefCounted
var catalogs: Dictionary = {}
var errors: Array[String] = []
func _init() -> void:
	for kind in ["weapon","passive","enemy","character","wave","evolution","rune","stage"]:
		var catalog: Dictionary = {}
		var path: String = "res://resources/"+kind+"s/"
		var directory := DirAccess.open(path)
		if directory == null:
			errors.append("Fehlender Katalog: "+path)
			continue
		var files := directory.get_files()
		files.sort()
		for file in files:
			if not file.ends_with(".tres"): continue
			var definition: Resource = load(path+file)
			if definition == null or definition.id.is_empty():
				errors.append("Ungültige Definition "+file)
				continue
			if catalog.has(definition.id): errors.append("Doppelte ID "+definition.id)
			if definition.weight <= 0 or definition.description.is_empty(): errors.append("Ungültige Werte "+file)
			catalog[definition.id]=definition
		catalogs[kind]=catalog
	for recipe in catalogs.get("evolution",{}).values():
		for base in recipe.values.bases:
			if not catalogs.weapon.has(base): errors.append("Ungültige Evolutionsbasis "+base)
		if not catalogs.passive.has(recipe.values.passive): errors.append("Ungültiger Katalysator")
	for weapon in catalogs.get("weapon",{}).values():
		if weapon.upgrades.size()!=7 or weapon.values.damage<=0 or weapon.values.cooldown<=0: errors.append("Ungültige Waffe "+weapon.id)
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
