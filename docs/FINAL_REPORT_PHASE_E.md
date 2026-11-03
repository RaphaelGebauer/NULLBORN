# Phase E final report

All six phases are implemented in the existing STERNENBRUCH project. Engine: **4.7.2.stable.official.ed1daf0bf**, GDScript 2.0, Compatibility renderer. E5 implementation: `5e474ca`. E6 implementation/publication hash is recorded in STATUS.md after commit. Existing Git history, saves and gameplay content are retained.

## Implemented systems

- E1/E2: measured runtime foundations and additive saves; 45 real Lv4 mutations; all fifteen normal evolution inheritances at full strength, both fusions with Primary 100% / Echo 50%, mandatory paused choices and no slot/recipe-gate changes.
- E3/E4: active five-band instability, four timed proximity rifts, seven bounded elite affixes, all three half-HP boss patterns/telegraphs, four bidirectional element reactions with local cooldown/global cap, correct damage ownership and no recursive procs.
- E5: a real connected three-branch Star Map with eighteen nodes, focus/hover inspector, visible costs/prerequisites/state, purchases, permanent Starlight and next-run snapshots. Full tree costs 63; each finish awards at most eight. Transactions persist immediately and roll back on failure. All stat/timed/conditional bonuses work. Recipient-specific damage factors are carried through derived mutation/reaction hits so the bonus applies once and never leaks to ineligible recipients.
- E6: very short desaturated flashes, readable critical numbers, bounded impacts and optional decaying boss-only shake; complete measured statistics/result pages and detailed live Build view. Fixed actions remain visible at all supported sizes. Secret recipes remain unnamed until actual execution. Known recipes include requirement readiness. Failed finish writes show pending rewards and a controller-accessible Retry Saving action.

## Functional acceptance

`STERNENBRUCH_LOG_DIR=/workspace/runtime/e6-correct-final ./tools/check.sh --long`

| Suite | PASS | FAIL | Coverage |
|---|---:|---:|---|
| Existing game / E1 | 179 | 0 | Resources, menus, equipment, waves, saves/migration/reset, progression, pacing, selection tools |
| Mutations | 404 | 0 | All 45 base/evolved effects, all normal inheritances, both fusion imprint combinations, budgets, mandatory FIFO/privacy |
| Rifts / elites / bosses | 103 | 0 | Bands, clock, four decisions, timing, all seven affixes, pooling, rewards, three boss patterns, warnings/caps |
| Reactions | 111 | 0 | Both orders, windows, priority, recipients, actual source sums, cap, boss dampening and proc guards |
| Constellations | 90 | 0 | Eighteen nodes/real effects, prices/chains, persistence, rollback/retry, six timed heals, snapshots, exact secondary factor inheritance |
| Polish / reports | 40 | 0 | Actual event statistics, overkill/healing, normal/Quick DPS, settings and feedback caps, Build/privacy, results/retry, both outcomes |
| Whole catalog | 49 | 0 | Actual damage from all 15 base + 15 evolved + 2 fusion attack algorithms; all 15 enemy AIs; both arena pipelines |
| **Total** | **976** | **0** | Import clean, no script/runtime errors or leaked instances |

## Complete simulations

All eighteen constellation nodes are active. Six mutations are selected and inherited through the real evolution API; choices, hits, kills, nodes and rewards use production logic. The harness provides immunity and automatic movement/choices to keep the simulation running. This is not a human winability/difficulty test.

| Measurement | Normal | Quick Mode |
|---|---:|---:|
| Run clock | 30:00 | 30:00 |
| Active combat time | 1800 s | 900 s |
| Victory signals | 1 | 1 |
| Kills / affixed elites | 26,343 / 23 | 13,013 / 22 |
| Boss Phase II transitions | 6, across all three kinds | 6, across all three kinds |
| Runes | 3 | 3 |
| Rifts stabilized / overcharged | 2 / 2 | 2 / 2 |
| Peak / final instability | 91.2 / 91.2 | 90.698 / 90.698 |
| Reaction events | 18,490, all four kinds | 8,809, all four kinds |
| Actual total damage | 10,861,180.39 | 5,018,293.49 |
| Average combat DPS | 6,033.99 | 5,575.88 |
| Highest actual critical hit | 132 | 132 |
| Starlight, booked exactly once | 8 | 8 |
| CPU wall time | 101.867 s | 50.902 s |

Normal fixture event counters: 19 upgrades, six mutations, six normal evolutions; Quick: eight upgrades, six mutations, six normal evolutions. Fusions are separately verified by mutation, catalog, polish and graphical fixtures; the complete-run loadout deliberately uses six normal evolutions. Damage rows reconcile with measured total. See `test-results/full-run.log` and `quick-run.log`.

Stress: **180 simulated seconds / 5,400 steps**, Critical instability, three Phase II bosses, affixed elites, inherited mutations and all stars. Peaks **382 enemies / 261 projectiles / 300 pickups**, 12,585 kills, 7,186 bounded reactions; **50.294 s** CPU wall time. Entity/hazard caps passed, no runtime errors. See `test-results/stress.log`. Timings depend on host/concurrent load and do not establish rendered FPS.

## Graphical and input acceptance

`DISPLAY=:99 ./tools/graphical_check.sh` and `DISPLAY=:99 ./tools/graphical_check.sh --wid 8388640` (actual X11 host ID for this session).

- Native 1280×720, 1600×900 and 1920×1080 resizing; ten audio changes without display requests.
- Original menu/character/arena/rune/level-up/shop/settings/collection/reset states, real keyboard movement and simulated analog-stick movement.
- Real mutation, inherited/fused imprint, rift decision, Phase II boss, reaction and Star Map captures.
- Build/result top and scrolled views at all three sizes, fixed action bounds, UI scale 1.2, four real character starts and controller-style scrolling.
- Native `--wid` embedding detected by Godot, no resize spam, no native display requests from audio/settings, controller action moves between constellation branches; embedded Star Map/Build/defeat captures.
- Representative screenshots were opened and inspected. Screenshot runners now resolve project-relative output paths. These scripted state captures are separate from the full per-step simulations.
- **33 graphical/input assertions passed**, with zero failures.
- Only the known llvmpipe VSync warning occurred. No script/runtime errors, resize errors or leaks.

## Main implementation and preservation

Data/UI: `scripts/data/constellations.gd`, `star_map.gd`, `run_report.gd`, `app.gd`. Runtime: `run_model.gd`, `run_statistics.gd`, `world.gd`, `player.gd`, `combat.gd`, `mutation_effects.gd`, `element_reactions.gd`. Persistence: `save_manager.gd`.

Unchanged: original 15 weapons, 17 passives, fifteen normal evolutions, two fusions, four heroes, two arenas, thirty waves, all twenty meta upgrades, six-plus-six slots, Lv5/Lv5/chest eligibility, discovery privacy and `resources/pacing.tres`. Existing valid saves gain additive defaults instead of a reset. No source TODO stubs or fake event statistics remain for requested features.

## Remaining manual / platform checks

- Physical gamepad behavior, audio device/loudness balancing and target desktop/editor focus/DPI/fullscreen behavior.
- GPU frame pacing on intended hardware; software rendering and headless timing do not prove stable target FPS.
- Human thirty-minute difficulty/playability on a fresh save and a progressed build.
- Native release exports/signing on desired target platforms. Debug shortcuts remain guarded by debug-build detection.

No known unresolved script/runtime/test failures remain. These manual/platform checks are not claimed as completed.

## Local play

1. Import `project.godot` using Godot **4.7.2 Stable** and press F5.
2. New Run → character/arena → rune. Reach weapon Lv4 for a real mutation choice.
3. Upgrade base weapon and matching passive to Lv5; collect a chest from a boss spawned at 10:00+ to evolve. Fusions keep Primary/Echo imprints.
4. Use F/controller Y near rifts. Pause → Build Details to inspect current stats and known paths.
5. Finish a run to inspect measured results and earn Starlight; unlock permanent stars from Main Menu → Star Map.
