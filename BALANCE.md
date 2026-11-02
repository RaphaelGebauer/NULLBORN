# Balance reference

## Editable definitions

| System | Source |
|---|---|
| 15 base weapons and seven upgrades each | `resources/weapons/*.tres` |
| 17 passive items | `resources/passives/*.tres` |
| 15 evolutions and 2 fusions | `resources/evolutions/*.tres` |
| 12 normal enemies, 3 bosses | `resources/enemies/*.tres` |
| 30 waves and boss/rune events | `resources/waves/*.tres` |
| 4 heroes, 8 runes, 2 stages | Corresponding `resources/` folders |
| Lantern drop weights | `resources/loot_table.tres` |
| 20 meta upgrades, prices and unlock rules | `scripts/save_manager.gd`, `META` |
| Stats, XP and selection tools | `scripts/run_model.gd` |
| Opening pace factors and ramp duration | `resources/pacing.tres` |
| Spawn scaling and enemy behavior | `scripts/world.gd` |

The generator `tools/generate_data.py` is retained. Regenerating overwrites catalog files; update it when changing generated definitions.

## Updated opening

Hero speed is multiplied by **0.75** before passive/meta modifiers. Base Lyra speed is **165 px/s** (previously 176), and the slowest hero starts at 153.75 px/s. A fresh normal mite moves at **97.5 px/s** (150 × 0.65), preserving an ample escape margin. Enemy movement starts at 0.65 and spawn rate at 0.4; both reach 1.0 over **480 in-game seconds**. This applies dynamically to movement, including charge and zigzag behavior. Weapon and enemy attack intervals start at ×1.2 and ease to ×1.0. Friendly/hostile projectile speeds and orbit/beam rotation start at ×0.8 and reach ×1.0. Beam/zone tick intervals use the same attack pacing. No global time-scale changes: run duration and minute/boss schedule remain intact.

Fleet Foot grants +5% movement speed per rank; base price 40 gold. Long Stride grants +1% per in-game minute per rank, capped at ten minutes. Momentum Feather grants +2% per minute per passive level, capped at five minutes. These are additive speed bonuses, recalculated from base values without compounding drift. Overall movement remains capped at 500 px/s.

### Additional tempo progression

All four added upgrades have five ranks and the standard quadratic rank pricing:

| Upgrade | Per-rank effect | Base price |
|---|---|---:|
| Swift Missiles | +6% projectile speed | 60 |
| Battle Rhythm | -1% cooldown per in-game minute, capped at ten minutes | 100 |
| Gathering Flow | +12% pickup attraction acceleration and maximum speed | 50 |
| Evasive Instinct | +3% movement speed while below 50% HP | 75 |

Timed cooldown is derived from the base recalculation, never incrementally compounded. Low-health speed is removed on healing above the threshold. Existing cooldown/movement caps still apply. Pace values are editable in `resources/pacing.tres`; the catalog generator does not overwrite this separate tuning resource.

## Selection tools

Runs start with zero rerolls, skips and banishes. Meta ranks grant their respective run charges (max 3/2/2). Treasure Hunter adds a reroll only if the reroll meta upgrade is already owned. Locked tool buttons are hidden; hotkeys cannot spend nonexistent charges.

## Evolutions

Recipe fields `weapon_level=5` and `passive_level=5` define thresholds. Existing weapon upgrades still go to Lv8. Eligible boss chests require the boss to have spawned at minute 10 or later. Fusions take priority. Passives remain equipped; a fusion frees one weapon slot. Evolution attack values are derived from the fully upgraded base and recipe overrides.

## New equipment

- Prism Disc: 15 damage, 1.7 s cooldown, 380 px/s, two bounces initially. Bounces select distinct nearby enemies, with deterministic distance/ID tie-breaks.
- Gravity Mine: 24 damage, 3.4 s cooldown, 95 px blast radius, 0.4 s arming delay, 4 s lifetime. Trigger radius 40 px; normal enemies are pulled up to 55 px and slowed.
- Reaper's Gaze: 18 damage, 2.8 s cooldown, 28 px hit radius. Targets lowest HP fraction; damage ×3 below 35% HP.
- Recovery Moss: +0.25 HP/s per level.
- Execution Seal: +8% direct damage per level against enemies at or below 35% HP.
- Frost Thorns: a 100 px slowing nova for 5 damage per level when contact damage is actually taken; I-frames prevent repeated triggers.
- Momentum Feather: timed movement bonus described above.

Caps remain: 6+6 equipment, 250 visible XP gems, 300 total pickups, 650 projectiles, 180 FX, 70 damage texts; 60% crit, area ×3, bonus amount +6, minimum cooldown 0.12 s. Max-HP changes preserve the current HP percentage. XP curve remains `round(8+9*(level-1)+0.2*(level-1)^2)`.

## Phase E work in progress

E1 provides tested save/runtime/statistics foundations; E2 implements all 45 weapon mutations and evolution/fusion inheritance. E3–E6 remain pending. See `docs/FEATURES_PHASE_E.md` and `STATUS.md` for the exact continuation point.

## E2 mutation tuning

45 definitions: `resources/mutations/*.tres`; regeneration script: `tools/generate_mutations.py`. Each definition has a base weapon, effect processor, interval, value and English explanation. The original generator does not overwrite this catalog. Mutation IDs use `mutation_` to avoid the pre-existing `last_judgment` evolution ID.

Mutation inheritance retains a runtime array of `{id, strength}` per owned weapon. Regular evolution transfers full strength. Fusion follows recipe base order: 1.0 then 0.5. Continuous modifiers scale their magnitude; integer/counter procs double their interval for echoes; chance procs halve chance; cooldown procs double cooldown. Shared secondary budget is 24 per simulation step, bounded by the existing 650 projectile / 180 FX limits. Secondary hits neither reroll crits nor re-enter mutation hooks, lifesteal or on-death cascades.

AoE impacts and zone ticks carry bounded event tokens so many targets do not falsely count as many casts/ticks. Afterglow/residual zones deliver four nonrecursive ticks totaling at most the configured damage fraction. Whiteout extends the refreshed base slow duration once, without repeated compounding or boss-freeze extension. Star Mark uses the strongest existing mark bonus, not an additional multiplier on the existing 15% mark.

## E3 runtime pressure

Instability gains 0.03 per run second, 4 per boss and 0.5 per affixed elite; ordinary kills add nothing. `rift_instability.gd` owns five current factors (never accumulated):

| Threshold | Band | Spawn | Speed | Contact | Boss/elite gold |
|---:|---|---:|---:|---:|---:|
| 0 | Dormant | 1 | 1 | 1 | +0% |
| 25 | Stirring | 1.05 | 1.03 | 1 | +10% |
| 50 | Fractured | 1.12 | 1.06 | 1.08 | +20% |
| 75 | Unstable | 1.20 | 1.10 | 1.12 | +30% |
| 90 | Critical | 1.25 | 1.12 | 1.20 | +40% |

`elite_affixes.gd`: first spawn at 05:00, then 70–90 / 55–75 / 45–65 run seconds at minutes 5/15/25. Fractured+ reduces intervals by 8%; alive caps 2/3 at instability 75. Only current-wave normal types; no splitters/children/bosses. Elite multipliers: HP 2.5 (+0.25 per extra affix, capped 3.5), damage 1.15 (+0.05, capped 1.35), speed 1.06, XP 2; Swift ×1.18, base speed capped 300 and final elite movement capped 320. Two affixes have 55% chance after 15:00 at 75+; three have 40% chance after 25:00 at 90+. Vampiric/Regenerating are mutually exclusive.

Elite rewards: 45 gold plus band bonus, 15% chance of a 10-HP heal pickup. Gold still passes through existing Greed on collection. Rift gold is direct round(120 × (1 + run_time / 1800)); XP is 0.35 × current required XP with no Growth multiplier. Rifts retry safe placement within their own 90-second slot only.

`boss_patterns.gd` owns separate HP phase/pattern state, 0.6-second transition, fixed dash warning/duration, safe-gap salvos, six children per Queen and four null zones globally. Hazards cap at 100 and projectiles at 650. Null zones warn for 1 second, last 2.5 active seconds, tick no faster than 0.8 seconds and refresh a nonstacking one-second 20% slow. Volatile explosions snapshot their values before pool reuse. No new factors modify immutable enemy definitions or the opening pacing resource.
