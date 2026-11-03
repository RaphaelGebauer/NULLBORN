# Equipment layout and combat balance acceptance

2026-11-03 · Continued published GitHub main `9f90a36`. Godot **4.7.2 Stable**, GDScript 2.0, Compatibility renderer. Existing content, stable IDs, save schema and progression are preserved.

## UI

Pause uses a shared read-only equipment view with **six equal-width weapon cards in one row** and **six passive cards in one row**. Occupied cards show the actual name and level; empty cards show a muted diamond. Real Grid/Center containers handle spacing/centering; long names wrap inside their own card. Runes are centered beneath equipment, followed by recipe counts, instability/status and the existing actions. At smaller viewports/UI scale 1.2, compact card padding/type and Pause actions preserve space.

Build uses **three columns × two rows** for each equipment category. Cards retain type (Base/Evolved/Fusion), level, behavior, passive effects and mutation name/effect/Primary 100%/Echo 50%. Empty slots show only a diamond. Hero/permanent bonuses, Runes, Current Stats, Temporary Effects, Elements/Reactions, discovered Evolution Paths and Rift Instability remain grouped below. Equipment is rebuilt on real inventory/rune signals; the view never recalculates/ticks/rolls or owns another inventory.

Build has **one centered fixed Back button**. Mouse, Enter, A, Esc and B all return to the original paused session; there is no Build Resume action. Run time, combat time, enemy/projectile state, player position, XP, gold, inventory and RNG remain unchanged by waiting or repeated inspection. Result actions remain unchanged. Main/character/arena/Star Map/choice/mutation/result screens were checked through the existing graphical suite; no unrelated redesign was needed.

## Balance

| Hero | Previous base speed | New base speed |
|---|---:|---:|
| Lyra | 156.75 | 125.4 |
| Brann | 146.0625 | 116.85 |
| Eira | 156.75 | 125.4 |
| Noctis | 174.5625 | 139.65 |

Values are px/s before the same additive bonuses and 500 cap. The existing central player_speed changes **0.7125 → 0.57**. Normal-enemy HP factor changes **1.0 → 1.2** once in spawn calculation; bosses stay **1.0**. Children/summons inherit this path, pools reset, elite multipliers remain 2.5/2.75/3.0. Player damage stays **0.93**. Enemy rewards, speed, damage, AI, schedules and normal/Quick time remain unchanged. No generated catalog was rewritten.

## Verification

Use fresh isolated XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME for **each invocation**. Engine: `/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`.

```sh
export GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
# Set each invocation's three XDG paths to fresh temporary directories.
./tools/check.sh --long
STERNENBRUCH_QUICK_TEST=1 "$GODOT_BIN" --headless --path . -s res://tests/full_run_runner.gd
DISPLAY=:99 ./tools/graphical_check.sh
DISPLAY=:99 ./tools/graphical_check.sh --wid 2097184
STERNENBRUCH_TEST_SEED=115 "$GODOT_BIN" --headless --path . -s res://tests/test_runner.gd
"$GODOT_BIN" --headless --path . -s res://tests/opening_probe.gd
```

Final verification: **1,238 functional PASS / 0 FAIL**, seven Python generator safety tests and exact staged generated outputs; independent seed 115 passes 179 unit checks. Native graphics: **221 assertions**, including **120 new layout/input checks**. Real embedded X11 host: **9 assertions**. Import/parser and final logs are clean: no script/engine errors, failed assertions or leaked instances. The known software-driver VSync warning remains.

Normal simulation: **30:00 / 1800 combat seconds**, one victory, 26,350 kills, 24 elites, six boss phase transitions, 20,216 reactions, 2 stabilizations / 2 overcharges and eight Starlight banked once; **60.814 s** CPU wall time. Quick: **30:00 / 900 combat seconds**, one victory, 13,092 kills, 22 elites, six transitions, 10,141 reactions, 2/2 rifts and eight Starlight once; **28.499 s**. Stress: **180 simulated seconds / 5400 steps**, peaks **382 enemies / 260 projectiles / 300 pickups**, 11,905 kills, 7,200 reactions; **27.353 s**. These cloud wall times are not GPU FPS or a controlled performance comparison.

Logs: `test-results/layout-{functional,graphical,embedded,seed115,opening,quick,full-run,stress}.log`. Reviewed captures include empty/full Pause and Build, inherited fusion mutations, long names, all three resolutions and UI scale 1.2. Existing captures from older checkpoints are historical; this pass adds `layout-*.png`. `git diff --check` passes. Runtime/resource changes versus `9f90a36` are limited to the equipment/report/App presentation, the single pacing resource and two lines at spawn; combat, player input, enemy resources, save code, catalog/generators and other gameplay helpers are unchanged.

 `tests/layout_balance_runner.gd` covers all four heroes and combined bonuses in both time modes, all fifteen enemy types at three minute/level/curse combinations, boss exemption, pool reuse, elite multipliers/non-repeat promotion, actual splitter/Queen children and byte-identical actual kill/drop rewards/RNG under old/new HP. It also tests live slot updates, pause snapshots, one Back action and actual fusion imprints/privacy. Existing copy/count/navigation expectations change only for the requested presentation and speed values; movement checks now assert displacement from actual speed and physics ticks rather than the obsolete absolute minimum.

`tests/layout_visual_runner.gd` covers empty/full equipment, real evolutions/fusion imprints, long names and rune counts, six-slot rows/3×2 grids, text height and card bounds, equal widths, fixed centered Back, scrolling and real mouse/keyboard/joypad input at all three requested resolutions and UI scales **1.0 and 1.2**. Captures: `docs/screenshots/layout-*.png`.

## Opening pressure and limits

See BALANCE.md and `test-results/layout-opening.log` for the no-immunity seed-115 probe. A non-adaptive circular route gives Brann **88.70 s** survival versus **180 s alive** on the previous balance; Lyra improves to 180 s alive, while Eira/Noctis die under both settings. First contact under current settings occurs after roughly 12–24 seconds on this route. Brann’s initial speed exceeds a fresh Mite by about 20%, but the unchanged ramp can erase that advantage after about 2½ minutes. This is a real opening-pressure concern for human testing; no extra balance adjustment was applied.

Full-run/stress fixtures use their pre-existing immunity and automatic movement/choices to test systems, clocks and budgets. They do not establish human winability. Software-rendered screenshots and synthetic joypad events do not prove physical controller behavior, desktop DPI/fullscreen, audible balance or target GPU frame pacing.
