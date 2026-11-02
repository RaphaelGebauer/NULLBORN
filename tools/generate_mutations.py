from pathlib import Path
import re,json
root=Path(__file__).resolve().parents[1]
rows=[]
for line in (root/'NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md').read_text().splitlines():
 if line.startswith('| `') and '**' in line:
  cols=line.split('|')[1:-1]
  weapon=cols[0].strip().strip('`')
  if not (root/f'resources/weapons/{weapon}.tres').exists():continue
  for col in cols[1:]:
   m=re.search(r'\*\*(.*?):\*\*',col)
   if m: rows.append((weapon,m.group(1)))
# English descriptions are the executable numerical contract shown to players.
data=[
('extra_attack',4,.5,'Every fourth attack adds a 50% damage shot or pulse.'),('primary',0,.15,'Deal 15% more damage to the primary target.'),('mark',0,.08,'Mark hits for 3 s; marked targets take +8% damage. Stronger marks replace this bonus.'),
('burn_chance',0,.25,'25% hit chance to burn for 3 s.'),('pierce',4,1,'+1 pierce; incompatible attacks gain a small pulse every fourth attack.'),('cooldown',0,-.12,'12% shorter weapon cooldown.'),
('periodic',4,.25,'A small pulse every 4 s deals 25% weapon damage.'),('radius',0,.12,'12% larger orbit radius.'),('chain_hit',5,.35,'Every fifth hit shocks a second nearby target for 35% damage.'),
('poison',0,3,'Hits poison for 3 s.'),('retaliate',2,.3,'Contact damage releases a 30% damage pulse; 2 s cooldown.'),('heal_hits',25,1,'Heal 1 HP every 25 hits, at most 3 HP per minute.'),
('chain',0,1,'One additional chain target, capped at four additional targets.'),('slowed_damage',0,.15,'15% more damage against slowed targets.'),('slow_chance',0,.15,'15% chance to slow for 1 s; reduced against bosses.'),
('slow_chance',0,.2,'20% chance to briefly slow a target.'),('extra_attack',3,.4,'Every third attack adds a 40% damage blade or pulse.'),('motion',0,.1,'10% faster weapon movement and rotation.'),
('frozen_blast',2,.35,'Frozen targets release a 45 px pulse for 35% damage; 2 s cooldown.'),('slow_duration',0,.35,'35% longer slows; boss freeze duration is unchanged.'),('extra_attack',4,.45,'Every fourth attack adds a 45% damage fragment or pulse.'),
('radius',0,.15,'15% larger effect radius.'),('delayed_attack',3,.35,'Every third attack repeats a 35% damage impact after 0.25 s.'),('charged',0,2,'Hits electrically charge targets for 2 s.'),
('extra_attack',4,.45,'Every fourth attack adds a 45% damage projectile or pulse.'),('marked_damage',0,.15,'15% more damage against marked targets.'),('reach',0,.15,'15% more projectile speed or effective reach.'),
('sunburn',.5,3,'Burn on hits, refreshed at most once per target per 0.5 s.'),('periodic',4,.3,'A secondary ray/pulse every 4 s deals 30% damage.'),('width',0,.12,'12% wider beam or effective hit radius.'),
('duration',0,.2,'20% longer effects.'),('snare',1,1,'Brief hit slow; at most one refresh per target per second.'),('bonus_hit',4,.3,'Every fourth successful tick adds 30% damage.'),
('comet_hits',4,.25,'Every fourth impact hits up to two other targets for 25% each.'),('afterglow',1,.3,'A one-second burning zone deals at most 30% of the impact damage.'),('knockback',0,10,'Small controlled knockback; bosses only receive a visual impact.'),
('bounce',0,2,'Two additional distinct-target ricochets; other attacks gain chain hits.'),('bounce_damage',0,.1,'10% more damage after the first bounce; never compounds.'),('expiry',3,.35,'Every third projectile/effect expiry releases a 35% pulse.'),
('extra_attack',4,.4,'Every fourth throw adds a 40% damage mine or pulse.'),('pull',0,.2,'20% stronger pull against normal enemies.'),('residual',1.5,.25,'Explosion leaves a 1.5 s slow zone, total damage capped at 25%.'),
('radius',0,.15,'15% larger hit radius.'),('execute_damage',0,.15,'15% more damage below 35% HP; does not repeat the base execute multiplier.'),('kill_chain',4,.35,'Every fourth direct kill hits another nearby enemy for 35% damage.')]
assert len(rows)==len(data)==45
for (weapon,name),(effect,interval,value,desc) in zip(rows,data):
 id='mutation_'+re.sub('[^a-z0-9]+','_',name.lower()).strip('_')
 vals=dict(weapon=weapon,effect=effect,interval=interval,value=value)
 s='[gd_resource type="Resource" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/data/mutation_definition.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
 for key,val in dict(id=id,display_name=name,description=desc,values=vals).items():s+=key+' = '+json.dumps(val,ensure_ascii=False)+'\n'
 (root/f'resources/mutations/{id}.tres').write_text(s)
