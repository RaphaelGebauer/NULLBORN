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

Hero speed is multiplied by **0.7125** before passive/meta modifiers (previous factor 0.75 × 0.95). Base Lyra/Eira speed is **156.75 px/s**, Brann **146.0625 px/s**, Noctis **174.5625 px/s**. All four heroes move exactly 5% slower before the unchanged 500 px/s cap. A fresh normal mite moves at **97.5 px/s** (150 × 0.65), preserving an ample escape margin. Enemy movement starts at 0.65 and spawn rate at 0.4; both reach 1.0 over **480 in-game seconds**. This applies dynamically to movement, including charge and zigzag behavior. Weapon and enemy attack intervals start at ×1.2 and ease to ×1.0. Friendly/hostile projectile speeds and orbit/beam rotation start at ×0.8 and reach ×1.0. Beam/zone tick intervals use the same attack pacing. No global time-scale changes: run duration and minute/boss schedule remain intact.

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

## Phase E — complete

E1–E6 are implemented and tested: mutations/inheritance, active rifts and phased bosses, elemental reactions, permanent Star Map, measured results and spoiler-safe Build Details. See `docs/FINAL_REPORT_PHASE_E.md` for complete regression evidence and remaining hardware/manual checks.

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

## E4 element reactions

Definitions live in `scripts/element_reactions.gd`, validated by Registry. Window: inclusive 3.0 combat seconds, target cooldown: 1.5, global cap: 40 events per integer combat second, at most six short visual labels (nearby labels coalesce). Combat time uses `combat.elapsed`, as existing status/mutation timers do; it stops on pause. Quick Mode doubles the run schedule, not combat movement/status time.

| Priority | Pair | Reaction | Actual effect based on final triggering-hit damage |
|---:|---|---|---|
| 1 | Frost + Storm | Arc Freeze | 35% primary, one additional target within 120 px for 30% |
| 2 | Fire + Toxin | Blightburst | 45% primary and up to seven others within 60 px; light existing Burn |
| 3 | Frost + Void | Void Shatter | 50% primary; 0.75-s slow (boss: 0.35 s) |
| 4 | Storm + Void | Rift Conduction | 25% to at most two additional targets within 140 px |

Boss recipients take 50% of these bonuses. Final triggering damage includes the original crit, execution and armor calculation once; bonus hits bypass that pipeline, round to the existing integer minimum-one damage, and cannot crit/mutate/react/leech or trigger death-fire chains. Radius checks use center distances after spatial broadphase; no target-hitbox expansion leaks into reaction range. Overkill is excluded by RunStatistics.

History stores at most five element timestamps/source IDs on each enemy. Fusion tags are a set union; one hit checks only prior history before applying all of its own tags. Secondary procs cannot apply new reaction history. Actual successful mutation/status applications can contribute tags; merely owning an off-target weapon or observing an old status cannot. Burn/Poison ownership is stored per enemy, overwritten on real refresh and reset on pool reuse; reaction Burn remains in `Elemental Reactions` and boss-damped, without a second Burn loop. Regenerating's fire lock now extends only on actual fire/status application or fire DoT, not unrelated hits during a visible burn.

World integration keeps all boss dashes free of crowd-separation drift. Blink warning/teleport frames suppress ordinary movement, so the 100–150 px side displacement remains true in actual AI, not just in the helper. These are regression-tested.

## E5 permanent constellations

The exact eighteen effects live in scripts/data/constellations.gd. Three ordered six-star paths cost 21 each (63 total); no duplicate buys. Starlight is separate from gold and capped at eight per finish. Comet movement bonuses add to existing speed bonuses under the 500 px/s cap; Veil Seed adds three flat HP. Rush refreshes a single 20-run-second deadline, Still Heart uses six five-minute opportunities and Last Star cannot resurrect. Hunter/Fracture damage bonuses affect each eligible recipient once, including secondary damage. Derived hits carry their inherited target factor so it can be removed and the new recipient's factor applied, avoiding double amplification and leakage to normal enemies. Tainted Treasure multiplies only eligible elite gold by 1.05. Risk Seeker multiplies only rift XP by 1.05, never Growth.

| Path | Star / cost | Effect |
|---|---|---|
| Comets | Comet Spark / 1 | +1% additive movement |
| Comets | Gathering Tail / 2 | +6 px magnet |
| Comets | Swift Orbit / 3 | +3% projectile speed |
| Comets | Astral Insight / 4 | +2% Growth |
| Comets | Rush of Stars / 5 | +2% movement for 20 run seconds after boss kill, refresh only |
| Comets | Far Traveler / 6 | +6 px magnet and +1% movement |
| Veil | Veil Seed / 1 | +3 flat maximum HP |
| Veil | Quiet Pulse / 2 | +0.05 HP/s |
| Veil | Guarded Orbit / 3 | Boss projectile damage ×0.97, existing minimum damage |
| Veil | Second Breath / 4 | Stabilization heals +4 HP |
| Veil | Still Heart / 5 | Heal 2 HP below half HP at each five-minute boundary, six opportunities |
| Veil | Last Star / 6 | Once: heal 8 HP below 25%, only while alive |
| Fractures | Rift Sense / 1 | Pause displays next instability threshold |
| Fractures | Tainted Treasure / 2 | Elite gold ×1.05 at instability 50+ |
| Fractures | Hunter's Star / 3 | Elite damage ×1.03 |
| Fractures | Clear Horizon / 4 | Stabilization removes 23 instead of 20 instability |
| Fractures | Risk Seeker / 5 | Rift XP ×1.05 (36.75% of current level requirement, no Growth) |
| Fractures | Fracture Mastery / 6 | Boss damage ×1.03 at instability 75+ |

## E6 feedback and statistics

Enemy hitflash ≤0.06 s, desaturated local tint; hero hitflash ≤0.07 s. Reduce Flashes suppresses these and reduces explosion/impact opacity. Normal incoming hits never shake. Strong boss damage (15+ before armor) may request ≤1.5 px/0.07 s; boss death ≤2 px/0.10 s. Deterministic sine motion is bounded by vector length, decays to zero and consumes no gameplay RNG. Disabling shake clears any current offset immediately. Critical text uses 17 px vs normal 15, gold tint and an exclamation mark, under the unchanged 70-text cap. Critical impacts share a 0.08-s throttle and the existing 180-effect cap.

Stats exclude overkill and overheal, separate base/evolved/fused sources, and record real crits/events. Average and peak ten-second DPS use active combat seconds; Quick Mode's run clock advances twice as fast, so a full Quick run has 900 combat seconds. Peak DPS uses eleven fixed buckets rather than unbounded hit history. UI fixtures may fast-forward the run clock for screenshots; real full-run tests integrate every simulation step and verify combat duration separately.

## Small global player-damage adjustment (2026-11-03)

`resources/pacing.tres` owns `player_damage = 0.93`. `RunModel.base_player_damage(value)` applies it once: `recalculate()` sets `might = stats.might × 0.93`, after additive hero/passive/meta bonuses. Combat.params and raw-weapon mutation retaliation/periodic hooks already use Might, so all 15 base weapons, 15 evolutions and two fusions retain their relative tuning. A base Might of 1 becomes 0.93; 1.5 becomes 1.395. Resource weapon damage values remain unchanged.

Fixed raw sources outside Might (Chain Spark, Frost Thorns, death-fire and fixed Burn/Poison ticks including reaction Burn) call the same helper at creation. Damage derived from a hit (mutation pulses/zones, split attacks and elemental reaction bonuses) inherits the already adjusted value; World.hit does not apply another global factor. Reaction Burn is a fixed tick, not a fraction of its triggering hit. Crit, execution, marks, armor and per-recipient constellation factors retain their existing order and attribution. Existing integer rounding/minimum-one damage means small individual hits/ticks need not fall by exactly 7%; the raw factor is exactly 0.93. Statistics measure the resulting real damage, excluding overkill.

No enemy resources, HP, incoming damage, healing, rewards, XP curve, wave schedule or Quick clock factors change. Player movement uses the one central `player_speed` value; timed/passive/meta/star bonuses remain additive and recalculation does not compound either reduction.
