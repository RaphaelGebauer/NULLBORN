# STERNENBRUCH — continuation status

Engine requirement: **Godot 4.7.2 Stable**, GDScript 2.0. Original brief preserved in `CODEX_MASTERPROMPT.md`; the latest user-requested English, progression and evolution changes override its earlier language/balance requirements.

## Phase E1 — completed foundation; E2–E6 not yet implemented

The uploaded Phase E specification is preserved as NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md. Full scope and exact continuation ledger: docs/FEATURES_PHASE_E.md.

Files: scripts/run_statistics.gd (real hit/health accounting, fixed DPS buckets), scripts/rift_instability.gd (tested state/bands), scripts/data/element_tags.gd (neutral/base/evolution/fusion tags), run_model.gd (run_delta and runtime ownership), world.gd (real damage/crit accounting), save_manager.gd (additive Starlight/node defaults and validation), app.gd (next-run constellation snapshot), registry.gd and tests/test_runner.gd.

E1 implementation commit: `9737363`.

Validation: Godot 4.7.2 Stable via tools/check.sh, 179 PASS / 0 FAIL, clean import, no script errors/leak reports. Existing gameplay/menu/evolution/save regression checks remain active. New migration tests preserve old gold, meta, recipes and settings; reset clears new fields. Pacing resource is unchanged.

Full-run regression with E1: 30:00, one victory, three runes, 23,923 kills, 76.527 s wall time, no script errors/leak reports. See test-results/full-run.log.

Next concrete task: E2. Add the 45 exact mutation definitions from the uploaded table; implement shared bounded hooks and inheritance before exposing mutation UI. Mutation choices must be inserted immediately after the level-up that reached Lv4; do not append behind already queued level-ups. Ordinary evolutions inherit 100%; fusion bases[0]/bases[1] inherit 100%/50%, with deterministic every-other-trigger handling for quantized echoes. Do not leak undiscovered recipes.

Not delivered yet: mutation gameplay/UI, active instability/director/rift nodes, affix elites, new boss phases, reactions, Star Map purchases/bonuses/currency awards, expanded result/build UI and requested new graphical captures. No false completion claim for the expansion.

## Latest overall pacing update

- Added central `resources/pacing.tres`: 0.75 hero movement, 0.65 initial enemy speed, 0.4 initial spawn density, 0.8 initial projectile/rotation speed and 1.2 initial attack intervals. Opening modifiers ease to normal over eight minutes; the run clock remains unchanged.
- Lyra now starts at 165 px/s. All four heroes retain a measured speed advantage over the early fast pursuer (97.5 px/s), rather than slowing the player alone.
- Meta shop now has 20 upgrades. Added Swift Missiles, Battle Rhythm, Gathering Flow and Evasive Instinct. Fleet Foot grants +5% per rank and starts at 40 gold. Existing saves retain their ranks and gold.
- Functional suite: **158 PASS / 0 FAIL**, clean import and no script errors/leak reports. Tests cover actual enemy/projectile/attack speed, all hero escape margins, ramp midpoint/end and each new meta effect.
- Updated full-run simulation: 30:00, one victory, three runes, 23,923 kills; 75.481 s wall time. Harness still uses immunity/automatic choices, so this is no claim of perfect human balance.
- Isolated armor/I-frame tests from previously selected random upgrades/runes to avoid order-dependent outcomes.

## Previous character/discovery/reset update

- Main-menu Characters is a read-only overview. Locked characters show their names only; no character entry can start a run. New Run retains its separate playable character picker.
- Successful evolutions/fusions persist in a separate `evolved_recipes` list. Pause and collection reveal only explicitly completed recipes. Component ownership and legacy `seen` flags do not leak them. Pause counts unknown paths linked to current weapons without naming recipes.
- Main-menu Settings includes Reset All Data with explicit confirmation and Cancel focused by default. It restores all save fields and settings, resets menu selections and drops stale session state. Tests use isolated save paths and do not reset real player progress.
- Fixed a stale removed-world reference exposed by resetting during repeated menu transitions in one frame.
- Current validation: 141 PASS, zero FAIL; clean import, no script errors or reported leaks. Graphical runner now renders 15 states including the overview, hidden/known recipes and reset confirmation. Combat balance is unchanged from the previous validated full run.

## Previous gameplay revision

Completed:

- Fixed repeated `Embedded window can't be resized.` messages: audio settings never mutate windows; native embedding is detected using `Engine.is_embedded_in_editor()` rather than relying on consumed CLI flags.
- Default standalone window: 1920×1080. Native resolution selection verified at 1280×720, 1600×900 and 1920×1080. Editor-embedded display controls are disabled with an explanation; existing saved resolution choices are preserved.
- English gameplay UI, equipment/hero/enemy names, descriptions, recipes, wave labels, settings and current documentation.
- Slower opening: hero base movement ×0.8; enemy movement starts ×0.85 and spawn density ×0.6, ramping to full values over five minutes.
- 16 meta upgrades. Added Long Stride, Renewal, Keen Eye, Wide Reach, Enduring Light and Quickening. Reroll/skip/banish have no free starting charges and only appear after purchase. Treasure Hunter cannot bypass the reroll unlock.
- Collection weapons, passives and heroes stay unknown until actual acquisition/selection, with immediate discovery persistence. Unlocking or seeing an offer does not reveal an entry.
- 15 base weapons, 17 passives, 15 evolutions plus 2 fusions. Added Prism Disc, Gravity Mine, Reaper's Gaze; Recovery Moss, Execution Seal, Frost Thorns, Momentum Feather; and three corresponding evolutions.
- Evolutions: base weapon Lv5+ + matching passive Lv5 + chest from a boss spawned at 10:00+. Fusions require both base weapons Lv5+. Passive catalysts are kept, not independently evolved.
- Player arrow points along the last movement direction, including hero decoration; camera/collision coordinates remain unrotated. Removed the direction dot.
- Existing saves retain gold, meta ranks, unlocks and settings; newly added weapons are merged into existing offer pools.

## Verified results

All current tests use **4.7.2.stable.official.ed1daf0bf**. The downloaded engine was verified against the official SHA512 manifest during initial setup. System-wide `godot` is older and must not be used.

- Import/parser/resource checks: passed. `test-results/import.log`.
- **158 PASS, zero FAIL**, no script errors or reported leaks in the current functional suite. Includes real new-weapon damage, ricochets, mine pull/slow, execution multiplier, passive retaliation, meta charge gating, timed speed growth, collection hiding, audio isolation, and Lv5/Lv5 thresholds. `test-results/unit.log`.
- Native graphical window test: ten audio changes cause no display requests; all three actual window sizes verified. `test-results/window.log`.
- True native embedded test, launched with `--wid`: no native window requests, no resize spam; settings explain editor ownership. `test-results/embedded.log`. The software driver emits only its known VSync-support warning.
- Previous graphical smoke test (before this tempo-only update): English screens rendered at 1920×1080; keyboard movement ~114.4 px and simulated stick movement ~55.8 px confirm the slower movement. Rotated arrow and settings screenshots visually inspected. `test-results/visual.log`, `docs/screenshots/`.
- Current complete accelerated run: reaches 30:00, emits victory once, processes three runes, 23,923 kills; ~75.481 s CPU wall time. `test-results/full-run.log`. Harness uses immunity and automated choices, not fake gameplay outcomes.
- Earlier sustained stress fixture: 180 simulated seconds / 5,400 steps, peaks 380 enemies / 261 projectiles / 300 pickups; 37.354 s wall time and no exceptions. `test-results/stress.log`. This log predates this revision; the current complete run and focused combat tests cover the changed systems.
- Test environment: Linux x86_64, AMD EPYC 7763, five visible vCPUs, ~33 GiB RAM; graphical tests use Xorg dummy + Mesa llvmpipe. Simulation timings are not a claim of rendered FPS.

## Original implementation history

Four original phases are preserved in Git:

- A `300e13c`: playable menu/player/combat/XP/result core, seven original checks.
- B `fe564b7`: original full combat catalog, statuses, spatial hash and pools.
- C `de4196b`: thirty waves, bosses, chest evolution/fusion, runes, arenas and modal flow.
- D `6e9cfc1`: saves, meta, unlocks, settings, original audio and the original 99-check validation.

No game was recreated during the latest revision. The initial four commits were uploaded to GitHub `main` and independently verified against a fresh bare clone before this revision.

## Remaining manual checks

Physical controller and target-platform focus behavior, audible audio balancing/device changes, fullscreen/DPI under a real window manager, human difficulty/playability over thirty minutes, and native release exports. Geometric original graphics and short synthesized audio are deliberate production simplifications. No known unresolved script/runtime failures in the current checks.

## Continue here

1. Read README.md, DESIGN.md and BALANCE.md. Use the existing isolated checkout; do not create a worktree unless explicitly requested.
2. Run `GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh`.
3. For combat changes, run `./tools/check.sh --long` with the same engine. For window changes, run the graphical window runner in standalone and true embedded modes.
4. Test physical hardware and human balance items from `docs/SMOKE_TEST.md`.
5. Existing cloud install/start draft pins the engine and XDG directories. Files persist; old game/display processes must not be assumed to survive. Updating a draft is separate from publishing the cloud configuration.
