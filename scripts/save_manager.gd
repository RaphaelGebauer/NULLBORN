extends RefCounted
var path: String="user://savegame.json"
var persistent: bool=true
var data: Dictionary={}
var warning: String=""
const META: Dictionary={
	"max_hp":{"name":"Vitality","effect":"+5 % Max-HP","cost":50,"max":5},
	"might":{"name":"Star Power","effect":"+3 % Damage","cost":75,"max":5},
	"speed":{"name":"Fleet Foot","effect":"+4% movement speed","cost":50,"max":5},
	"magnet":{"name":"Attraction","effect":"+10 px magnet radius","cost":50,"max":5},
	"growth":{"name":"Insight","effect":"+4 % XP","cost":75,"max":5},
	"greed":{"name":"Treasure Gleam","effect":"+5 % Gold","cost":75,"max":5},
	"armor":{"name":"Star Armor","effect":"+1 armor every 2 ranks","cost":100,"max":5},
	"rerolls":{"name":"New Paths","effect":"Unlock +1 reroll per run","cost":125,"max":3},
	"skips":{"name":"Let Go","effect":"Unlock +1 skip per run","cost":100,"max":2},
	"banishes":{"name":"Banishment","effect":"Unlock +1 banish per run","cost":150,"max":2},
	"long_stride":{"name":"Long Stride","effect":"+1% speed per minute per rank, caps at 10 minutes","cost":100,"max":5},
	"regeneration":{"name":"Renewal","effect":"+0.15 HP regeneration per second","cost":100,"max":5},
	"crit":{"name":"Keen Eye","effect":"+2% critical chance","cost":100,"max":5},
	"area":{"name":"Wide Reach","effect":"+4% weapon radius","cost":75,"max":5},
	"duration":{"name":"Enduring Light","effect":"+5% effect duration","cost":75,"max":5},
	"cooldown":{"name":"Quickening","effect":"-2% weapon cooldown","cost":125,"max":5}}
func _init() -> void:
	data=defaults()
func defaults() -> Dictionary:
	return {"version":1,"total_gold":0,"unlocked_characters":["lyra"],"unlocked_stages":["mist"],"unlocked_weapons":["arcane_needle","ash_bow","spark_orbit","thorn_halo","lightning_call","moon_blade","frost_shard","storm_bomb","shadow_fan","sun_beam","soul_well","meteor_rain","prism_disc","gravity_mine","reaper_gaze"],"unlocked_runes":["shard_star","resonance","blood_moon","ice_crown","treasure","chain_spark","shield_sign","time_anchor"],"meta_powerups":{},"achievements":[],"best_run_records":{},"seen":[],"evolved_recipes":[],"stats":{"kills":0,"bosses":0,"runs":0,"wins":0,"gold_earned":0,"best_time":0.0},"settings":{"master":.8,"music":.35,"sfx":.65,"fullscreen":false,"resolution":2,"screen_shake":true,"reduce_flash":false,"damage_texts":true,"deadzone":.2,"ui_scale":1.0}}
func load_save() -> bool:
	data=defaults()
	if not FileAccess.file_exists(path): return true
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null:
		warning="Could not read the save file."
		return false
	var parser:=JSON.new()
	var error: Error=parser.parse(file.get_as_text())
	var parsed: Variant=parser.data if error==OK else null
	if not valid(parsed):
		warning="Corrupted or incompatible save: backup created and defaults loaded."
		DirAccess.copy_absolute(path,path+".corrupt.bak")
		return false
	for key in data:
		if parsed.has(key):
			if data[key] is Dictionary: data[key].merge(parsed[key],true)
			else: data[key]=parsed[key]
	for id in ["prism_disc","gravity_mine","reaper_gaze"]:
		if not id in data.unlocked_weapons: data.unlocked_weapons.append(id)
	return true
func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version",0)!=1: return false
	var base:=defaults()
	for key in base:
		if not value.has(key): continue
		if typeof(value[key])!=typeof(base[key]) and not (value[key] is float and base[key] is int): return false
	if float(value.get("total_gold",0))<0: return false
	for key in ["stats","settings","meta_powerups"]:
		var content: Dictionary=value.get(key,{})
		for entry in content:
			if key=="meta_powerups":
				if not META.has(entry) or not (content[entry] is float or content[entry] is int) or content[entry]<0 or content[entry]>META[entry].max: return false
			elif base[key].has(entry):
				var expected: Variant=base[key][entry]
				if expected is bool and not content[entry] is bool: return false
				if (expected is float or expected is int) and not (content[entry] is float or content[entry] is int): return false
	for key in value.get("best_run_records",{}):
		var record: Variant=value.best_run_records[key]
		if not record is Dictionary: return false
		for field in ["time","kills","level"]:
			if not (record.get(field,0) is int or record.get(field,0) is float): return false
	for key in ["unlocked_characters","unlocked_stages","unlocked_weapons","unlocked_runes","achievements","seen","evolved_recipes"]:
		for entry in value.get(key,[]):
			if not entry is String: return false
	return true
func save() -> bool:
	if not persistent: return true
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t"))
	file.flush()
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path)==OK
func price(id: String) -> int:
	return META[id].cost*int(pow(data.meta_powerups.get(id,0)+1,2))
func buy(id: String) -> bool:
	if not META.has(id): return false
	var rank: int=data.meta_powerups.get(id,0)
	if rank>=META[id].max or data.total_gold<price(id): return false
	data.total_gold-=price(id)
	data.meta_powerups[id]=rank+1
	save()
	return true
func discovered(id: String, kind: String) -> bool:
	if kind=="evolution": return id in data.evolved_recipes
	return kind=="stage" or id in data.seen
func reset_all() -> bool:
	var previous: Dictionary=data
	data=defaults()
	if not save():
		data=previous
		warning="Could not reset the save file. Your progress has been kept."
		return false
	warning=""
	return true
func mark_evolved(id: String) -> void:
	if not id in data.evolved_recipes: data.evolved_recipes.append(id)
	mark_seen(id)
func mark_seen(id: String) -> void:
	if not id in data.seen: data.seen.append(id)
func unlocks(kills: int,bosses: int,time: float,won: bool,evolutions: Array,passives: Dictionary) -> Array:
	var added: Array=[]
	var achievements: Dictionary={"first_100":kills>=100,"total_1000":data.stats.kills+kills>=1000,"survive_5":time>=300,"survive_10":time>=600,"survive_20":time>=1200,"survive_30":time>=1800,"first_boss":bosses>0,"first_evolution":not evolutions.is_empty(),"first_fusion":evolutions.any(func(id):return id in ["dusk_storm","day_night"]),"first_win":won,"gold_10000":data.stats.gold_earned>=10000}
	var count: int=0
	for id in data.seen:
		if id in ["power_core","clockwork","runner_boots","focus_lens","multiplicity","lasting_seal","magnet_ring","blood_vial","iron_skin","growth_crown","lucky_die","wind_feather","greed_amulet"]: count+=1
	achievements["passives_10"]=count>=10
	for id in achievements:
		if achievements[id] and not id in data.achievements:
			data.achievements.append(id)
			added.append(id)
	for pair in [["brann",data.stats.kills+kills>=1000],["noctis",time>=600],["eira",bosses>0]]:
		if pair[1] and not pair[0] in data.unlocked_characters:
			data.unlocked_characters.append(pair[0])
			added.append(pair[0])
	if won and not "ash" in data.unlocked_stages:
		data.unlocked_stages.append("ash")
		added.append("ash")
	return added
func finish_run(model: RefCounted,victory: bool) -> Array:
	if model.banked: return []
	model.banked=true
	for id in model.evolutions: mark_evolved(id)
	var earned: int=roundi(model.gold*(1+model.curse))
	data.total_gold+=earned
	data.stats.gold_earned+=earned
	var added: Array=unlocks(model.kills,model.bosses,model.time,victory,model.evolutions,model.passives)
	data.stats.kills+=model.kills
	data.stats.bosses+=model.bosses
	data.stats.runs+=1
	data.stats.wins+=1 if victory else 0
	data.stats.best_time=maxf(data.stats.best_time,model.time)
	var key: String=model.stage+("_fast" if model.fast else "_normal")
	var previous: Dictionary=data.best_run_records.get(key,{"time":0,"kills":0})
	if model.time>=previous.time: data.best_run_records[key]={"time":model.time,"kills":model.kills,"level":model.level}
	save()
	return added
