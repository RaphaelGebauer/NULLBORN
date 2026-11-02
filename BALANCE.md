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
| 16 meta upgrades, prices and unlock rules | `scripts/save_manager.gd`, `META` |
| Stats, XP and selection tools | `scripts/run_model.gd` |
| Opening ramp, spawn scaling and enemy behavior | `scripts/world.gd` |

The generator `tools/generate_data.py` is retained. Regenerating overwrites catalog files; update it when changing generated definitions.

## Updated opening

Hero speed is multiplied by 0.8 before passive/meta modifiers. Base Lyra speed is 176 px/s. Enemy speed starts at 0.85 of its normal value and spawn rate at 0.6; both reach 1.0 over 300 in-game seconds. The underlying minute-based difficulty formulas remain intact.

Fleet Foot grants +4% movement speed per rank. Long Stride grants +1% per in-game minute per rank, capped at ten minutes. Momentum Feather grants +2% per minute per passive level, capped at five minutes. These are additive speed bonuses, recalculated from base values without compounding drift. Overall movement remains capped at 500 px/s.

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
