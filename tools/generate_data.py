"""Original STERNENBRUCH definitions; generator is retained for reproducible balancing."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
def put(p,s):
 p=root/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s)
put(Path('scripts/data/definition.gd'),'''extends Resource
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weight: float = 100
@export var values: Dictionary = {}
@export var upgrades: Array[Dictionary] = []
''')
for kind in ['weapon','passive','enemy','character','wave','evolution','rune','stage']:
 put(Path(f'scripts/data/{kind}_definition.gd'),'extends "res://scripts/data/definition.gd"\n')
def variant(x):
 if isinstance(x,str): return json.dumps(x,ensure_ascii=False)
 if isinstance(x,bool):return str(x).lower()
 if isinstance(x,dict):return '{'+', '.join(variant(k)+': '+variant(v) for k,v in x.items())+'}'
 if isinstance(x,list):return '['+', '.join(map(variant,x))+']'
 return str(x)
def resource(kind,id,name,values,desc='',upgrades=None,weight=100):
 s=f'[gd_resource type="Resource" script_class="" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/data/{kind}_definition.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
 for k,v in dict(id=id,display_name=name,description=desc or name,weight=weight,values=values).items():s+=k+' = '+variant(v)+'\n'
 if upgrades:s+='upgrades = Array[Dictionary]('+variant(upgrades)+')\n'
 put(Path(f'resources/{"enemies" if kind=="enemy" else kind+"s"}/{id}.tres'),s)
weapons=[
 ('arcane_needle','Arcane Needle','needle',13,.85,450,1,10,0,0),
 ('ash_bow','Ash Bow','fan',8,1.35,330,3,10,0,0),
 ('spark_orbit','Spark Orbit','orbit',9,.65,0,2,70,3,0),
 ('thorn_halo','Thorn Halo','aura',5,.75,0,1,65,0,0),
 ('lightning_call','Lightning Call','lightning',22,2.6,0,1,45,0,0),
 ('moon_blade','Moon Blade','boomerang',17,1.6,340,1,20,1.6,0),
 ('frost_shard','Frost Shard','needle',12,1,520,1,10,0,0),
 ('storm_bomb','Storm Bomb','bomb',27,3.1,0,1,75,0,0),
 ('shadow_fan','Shadow Fan','radial',9,2,360,8,10,0,0),
 ('sun_beam','Sun Beam','beam',7,2.5,0,1,220,1.1,.25),
 ('soul_well','Soul Well','zone',6,5,0,1,80,3,.5),
 ('meteor_rain','Meteor Rain','meteor',14,2.8,0,3,38,0,0)]
anchors={
'arcane_needle':{4:{'pierce':1},6:{'count':1},8:{'pierce':2}},
'ash_bow':{3:{'count':2},4:{'burn':1},6:{'spread':.4},8:{'count':2}},
'spark_orbit':{3:{'count':1},4:{'rotation':.6},6:{'count':1},8:{'radius':15}},
 'thorn_halo':{3:{'radius':15},5:{'radius':15},7:{'slow':1},8:{'cooldown':-.15}},
'lightning_call':{3:{'count':1},5:{'chain':1},8:{'count':2}},
'moon_blade':{4:{'count':1},6:{'pierce':3},8:{'count':1}},
'frost_shard':{3:{'count':1},5:{'pierce':1},8:{'split':1}},
'storm_bomb':{3:{'radius':20},5:{'burn':1},7:{'cooldown':-.35},8:{'echo':1}},
'shadow_fan':{3:{'count':4},5:{'poison':1},8:{'echo':1}},
'sun_beam':{3:{'duration':.4},5:{'radius':70},8:{'count':1}},
'soul_well':{3:{'duration':1.5},5:{'pull':1},7:{'radius':25},8:{'count':1}},
'meteor_rain':{3:{'count':2},5:{'burn':1},7:{'radius':12},8:{'count':3}}}
labels={'damage':'Damage','pierce':'Pierce','count':'Amount','burn':'Burn','spread':'Spread','rotation':'Rotation','radius':'Radius','slow':'Slow','cooldown':'Cooldown (s)','chain':'Chain targets','split':'Shards','echo':'Echo','duration':'Duration (s)','poison':'Poison','pull':'Pull'}
for i,(id,name,behavior,damage,cd,speed,count,radius,duration,tick) in enumerate(weapons):
 upgrades=[]
 for lv in range(2,9):
  delta=anchors.get(id,{}).get(lv,{'damage':round(damage*.15,2)})
  upgrades.append(dict(delta=delta,text=', '.join(f'{labels[k]} {v:+g}' for k,v in delta.items())))
 vals=dict(behavior=behavior,damage=damage,cooldown=cd,speed=speed,count=count,radius=radius,duration=duration,tick=tick,pierce=0,spread=.7,rotation=2.4,color=i/12)
 if id=='frost_shard':vals['slow_chance']=.3
 resource('weapon',id,name,vals,f'{name}: {damage} Damage · {cd:g} s · '+{'needle':'targeted projectile','fan':'directional fan','orbit':'orbiting spheres','aura':'permanent aura','lightning':'lightning strike','boomerang':'returning crescent','bomb':'delayed explosion','radial':'radial volley','beam':'rotating beam','zone':'stationary pull zone','meteor':'meteor strikes'}[behavior],upgrades,100 if i<4 else 60 if i<9 else 25)
passives=[('power_core','Power Core','might',.1),('clockwork','Clockwork','cooldown',-.07),('runner_boots','Runner Boots','speed',.08),('focus_lens','Focus Lens','area',.1),('multiplicity','Multiplicity','amount',1),('lasting_seal','Lasting Seal','duration',.12),('magnet_ring','Magnet Ring','magnet',25),('blood_vial','Blood Vial','max_hp',.15),('iron_skin','Iron Skin','armor',1),('growth_crown','Growth Crown','growth',.1),('lucky_die','Lucky Die','luck',.1),('wind_feather','Wind Feather','projectile_speed',.1),('greed_amulet','Greed Amulet','greed',.12)]
for id,name,stat,bonus in passives:
 stat_name={'might':'weapon damage','cooldown':'cooldown','speed':'movement speed','area':'area radius','amount':'projectile count','duration':'duration','magnet':'magnet radius (px)','max_hp':'maximum HP','armor':'armor','growth':'XP gain','luck':'luck','projectile_speed':'projectile speed','greed':'gold gain'}[stat]
 desc='+1 projectile at Lv2/4; otherwise +5% projectile damage' if id=='multiplicity' else (f'{bonus*100:+g} % {stat_name} per level' if abs(bonus)<1 else f'{bonus:+g} {stat_name} per level')
 resource('passive',id,name,dict(stat=stat,bonus=bonus),desc)
enemies=[('wisp','Flicker Wisp',14,85,6,1,12),('mite','Star Mite',8,150,4,1,8),('crawler','Maw Crawler',24,105,8,2,14),('guardian','Mist Guardian',70,60,12,4,22),('charger','Shard Charger',35,95,10,3,13),('sniper','Shadow Caller',40,75,7,4,14),('zigzag','Crystal Flier',28,145,8,3,11),('splitter','Fractureling',48,90,9,4,18),('shield','Iron Sentinel',110,65,14,6,22),('healer','Haze Priest',50,70,7,5,16),('bomber','Void Bomber',36,110,12,4,17),('elite_hunter','Elite Hunter',180,115,16,14,23),('astral_guardian','Astral Guardian',850,65,18,60,40),('void_queen','Void Queen',1250,75,20,80,43),('storm_core','Storm Core',2400,80,24,100,48)]
for i,(id,name,hp,speed,damage,xp,radius) in enumerate(enemies): resource('enemy',id,name,dict(hp=hp,speed=speed,damage=damage,xp=xp,radius=radius,boss=i>=12,color=i/15),name+' · '+str(hp)+' HP')
characters=[('lyra','Lyra · Star Runner','arcane_needle',100,220,{'growth':.1}),('brann','Brann · Ash Warden','ash_bow',125,205,{'armor':1,'cooldown':-.05}),('noctis','Noctis · Moon Hunter','moon_blade',85,245,{'crit_factor':.15,'luck':.1}),('eira','Eira · Frost Seer','frost_shard',95,220,{'area':.15,'projectile_speed':.1})]
for id,name,weapon,hp,speed,bonuses in characters:resource('character',id,name,dict(weapon=weapon,hp=hp,speed=speed,bonuses=bonuses))
recipes=[('star_piercer','Star Piercer','power_core',{'count':3,'speed':800,'pierce':5,'mark':1}),('phoenix_fan','Phoenix Fan','runner_boots',{'count':7,'burn':1,'death_fire':1}),('solar_orbit','Solar Orbit','lasting_seal',{'count':6,'pulse':1}),('blood_thorns','Blood Thorns','iron_skin',{'radius':125,'reflect':1,'leech_hits':15}),('thunder_grid','Thunder Grid','lucky_die',{'count':4,'chain':3}),('crescent_storm','Crescent Storm','focus_lens',{'count':3,'spiral':1,'radius':32,'pierce':8}),('ice_prism','Ice Prism','wind_feather',{'split':1,'slow':1,'freeze_chance':.08}),('meteor_heart','Meteor Heart','growth_crown',{'radius':120,'secondary':5}),('night_storm','Night Storm','multiplicity',{'count':16,'echo':1,'poison':1}),('zenith_beam','Zenith Beam','clockwork',{'count':2,'duration':2.8,'counter':1}),('ghost_well','Ghost Well','blood_vial',{'count':2,'pull':1,'leech_kills':20,'radius':110}),('comet_shower','Comet Shower','magnet_ring',{'count':10,'pull':1,'radius':55})]
for base,recipe in zip(weapons,recipes):
 id,name,passive,changes=recipe
 resource('evolution',id,name,dict(bases=[base[0]],passive=passive,weapon_level=5,passive_level=5,changes=changes),base[1]+' Lv5+ + '+next(p[1] for p in passives if p[0]==passive)+' Lv5; boss chest spawned at 10:00+.')
resource('evolution','dusk_storm','Dusk Storm',dict(bases=['ash_bow','frost_shard'],passive='runner_boots',weapon_level=5,passive_level=5,changes={'behavior':'radial','count':20,'burn':1,'slow':1,'echo':1}), 'Ash Bow Lv5+ + Frost Shard Lv5+ + Runner Boots Lv5; boss chest spawned at 10:00+.')
resource('evolution','day_night','Day and Night',dict(bases=['moon_blade','sun_beam'],passive='focus_lens',weapon_level=5,passive_level=5,changes={'behavior':'orbit','count':2,'radius':120,'diameter':1,'pierce':8}), 'Moon Blade Lv5+ + Sun Beam Lv5+ + Focus Lens Lv5; boss chest spawned at 10:00+.')
runes=[('shard_star','Shard Star','Needle/Frost: +1 projectile'),('resonance','Battle Resonance','Every 20 kills −15 % cooldown for 3 s'),('blood_moon','Blood Moon','Every 30 kills +3 HP (max. 30 HP/min)'),('ice_crown','Ice Crown','8% slow chance on direct hits'),('treasure','Treasure Hunter','+25 % Gold and +1 reroll if unlocked in the meta shop'),('chain_spark','Chain Spark','5% chain lightning (0.25 s internal cooldown)'),('shield_sign','Shield Sign','10% chance to block damage'),('time_anchor','Time Anchor','+25% orbit, zone and beam duration')]
for id,name,desc in runes:resource('rune',id,name,{},desc)
resource('stage','mist','Mist Heath',{'density':1.0,'background':'101e29','accent':'416d69'},'Dark heath beneath broken stars')
resource('stage','ash','Star Ash',{'density':1.1,'background':'251d30','accent':'88608a'},'Crystal craters · +10% enemy density')
waves=[{'wisp':80,'mite':20},{'wisp':55,'mite':30,'crawler':15},{'mite':50,'crawler':35,'wisp':15},{'guardian':20,'crawler':50,'mite':30},{'crawler':50,'charger':20,'wisp':30},{'crawler':65,'guardian':35},{'zigzag':35,'mite':35,'crawler':30},{'sniper':15,'zigzag':35,'crawler':50},{'splitter':20,'zigzag':40,'charger':40},{'elite_hunter':8,'guardian':30,'zigzag':62},{'zigzag':60,'guardian':40},{'mite':45,'sniper':20,'splitter':35},{'shield':15,'charger':35,'crawler':50},{'healer':12,'shield':23,'zigzag':65},{'bomber':25,'zigzag':40,'guardian':35},{'elite_hunter':30,'guardian':70},{'splitter':30,'mite':40,'healer':30},{'sniper':30,'bomber':30,'shield':40},{'charger':45,'zigzag':30,'elite_hunter':25},{'shield':35,'healer':20,'elite_hunter':45},{'sniper':30,'splitter':30,'zigzag':40},{'splitter':35,'sniper':30,'bomber':35},{'elite_hunter':35,'zigzag':45,'guardian':20},{'healer':15,'shield':35,'bomber':50},{'mite':45,'elite_hunter':30,'zigzag':25},{'guardian':40,'elite_hunter':60},{'shield':35,'sniper':25,'elite_hunter':40},{'bomber':40,'zigzag':30,'charger':30},{'healer':20,'shield':30,'elite_hunter':50},{'elite_hunter':45,'guardian':30,'zigzag':25}]
for minute,weights in enumerate(waves):resource('wave',f'wave_{minute:02}',f'Wave {minute+1:02} · Sternenbruch',dict(minute=minute,weights=weights,boss={5:'astral_guardian',10:'void_queen',15:'astral_guardian',20:'void_queen',25:'astral_guardian',29:'storm_core'}.get(minute,''),rune=minute in [11,21]))
for id,name,behavior,damage,cd,speed,radius,duration in [
 ('prism_disc','Prism Disc','ricochet',15,1.7,380,12,0),
 ('gravity_mine','Gravity Mine','mine',24,3.4,0,95,4),
 ('reaper_gaze',"Reaper's Gaze",'execution',18,2.8,0,28,0)]:
 upgrades=[]
 for lv in range(2,9):
  delta={'damage':round(damage*.15,2)}
  if lv in [3,6]: delta={'bounces':1} if behavior=='ricochet' else {'radius':15} if behavior=='mine' else {'cooldown':-.2}
  upgrades.append({'delta':delta,'text':', '.join(f'{k.title()} {v:+g}' for k,v in delta.items())})
 values=dict(behavior=behavior,damage=damage,cooldown=cd,speed=speed,count=1,radius=radius,duration=duration,tick=.5,pierce=0,spread=.7,rotation=2.4,color=.8,bounces=2 if behavior=='ricochet' else 0)
 resource('weapon',id,name,values,{'ricochet':'Discs bounce between different enemies, up to 240 px apart.','mine':'Arms after 0.4 s; nearby enemies trigger an implosion that pulls and slows.','execution':'Targets the weakest enemy; triple damage below 35% health.'}[behavior],upgrades,60)
for id,name,stat,bonus,desc in [
 ('recovery_moss','Recovery Moss','regeneration',.25,'Regenerate 0.25 HP/s per level.'),
 ('execution_seal','Execution Seal','execution',.08,'Deal +8% damage per level to enemies below 35% HP.'),
 ('frost_thorns','Frost Thorns','retaliation',5,'Taking contact damage releases a slowing frost nova: 5 damage per level.'),
 ('momentum_feather','Momentum Feather','momentum',.02,'Gain +2% movement speed per minute per level; caps after 5 minutes.')]:
 resource('passive',id,name,dict(stat=stat,bonus=bonus),desc)
for id,name,base,passive,changes in [
 ('spectral_carousel','Spectral Carousel','prism_disc','execution_seal',{'count':3,'bounces':7,'speed':500}),
 ('event_horizon','Event Horizon','gravity_mine','momentum_feather',{'radius':160,'damage':65,'count':2,'duration':5}),
 ('last_judgment','Last Judgment','reaper_gaze','recovery_moss',{'damage':60,'cooldown':1.4,'radius':65})]:
 resource('evolution',id,name,dict(bases=[base],passive=passive,weapon_level=5,passive_level=5,changes=changes),base.replace('_',' ').title()+' Lv5+ + '+passive.replace('_',' ').title()+' Lv5; boss chest spawned at 10:00+.')
print('Generated original typed resource catalog')
