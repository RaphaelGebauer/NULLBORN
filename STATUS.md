# STERNENBRUCH — continuation status

Engine requirement: **Godot 4.7.2 Stable**, GDScript 2.0. Original brief preserved in `CODEX_MASTERPROMPT.md`; the latest user-requested English, progression and evolution changes override its earlier language/balance requirements.

## Phase E5 — complete and tested; E6 next

Implementation hash recorded after commit. Data: scripts/data/constellations.gd; interactive connected three-branch Star Map: scripts/star_map.gd and app.gd. All eighteen specified nodes/costs/prerequisites and real combat/stat/rift/timed hooks are implemented. Total cost 63 Starlight; rewards capped at eight, booked exactly once at finish. Save failures roll back both purchases and finish rewards and expose a retry message. Existing version-1 saves/migration/reset retained; active runs use independent snapshots. No changes to opening pacing or mutation/evolution gates.

Godot 4.7.2 Stable, tools/check.sh: **797 preserved + 85 constellation tests = 882 PASS / 0 FAIL**, no script errors/leaks. Tests cover all nodes, costs, prerequisites, restart persistence, failed-write rollback/retry, capped/idempotent finish, every bonus, six Still Heart boundaries in both modes, no recalculation stacking, real rift/elite/boss/projectile integration, UI focus and snapshot isolation. Real graphical captures at 1280×720, 1600×900 and 1920×1080; 1280 capture inspected, all eighteen stars, inspector and Back visible. Known llvmpipe VSync warning only. Logs in test-results/constellations.log and star-visual.log.

Next E6: subtle bounded feedback, complete measured statistics/result view with fixed reachable actions, spoiler-safe Build Details, full regression/30-minute/stress/window/embedded checks and synchronized documentation. Do not claim E6 complete before these checks.

## Phase E4 — implemented and verified; E5–E6 remain open

Implementation commit: `8f07815`; pushed to GitHub main and independently verified with ls-remote plus a fresh bare clone containing project.godot, the reaction helper, tests and STATUS.md. E3 implementation `aee0e53` is also published and verified.

- scripts/element_reactions.gd implements Arc Freeze, Blightburst, Void Shatter and Rift Conduction in both orders, on actual final hits, with fixed priority, 3-second element history, shared 1.5-second target cooldown and global forty-events-per-combat-second budget.
- Cached immutable weapon/evolution/fusion tag unions plus successfully applied mutation/status tags; existing Ice Crown contributes Frost only on its real successful hit. No inventory-only or stale-status triggers; no first-hit self-reaction from a fusion union.
- Real bounded primary/chain/AoE effects, exact center-distance radii, half bonus against boss recipients, no repeated crit/execution/armor pipeline and no reaction/mutation/lifesteal/death-fire recursion. Separate actual `Elemental Reactions` damage with no overkill duplication. Burn/Poison retain their real source, reaction Burn stays reaction-attributed and boss-damped without duplicate ticks.
- At most six brief visual labels/rings with nearby label coalescing, Reduce Flashes respected; English pause legend and actual damage/event result entry. No secret recipe disclosure.
- Integration review fixed three existing edge cases: unrelated hits during Burn no longer extend Regenerating's fire lock; boss dashes cannot be bent by crowd separation; blinking elites remain still during the warning and teleport frame, preserving their exact displacement. New real-World regression tests cover these cases.
- Saves, all existing equipment/imprints/evolution gates, ordinary 6+6 slots and resources/pacing.tres preserved. No E5 purchases/currency awards or E6 completion claim.

Final validation: Godot **4.7.2.stable.official.ed1daf0bf**, `STERNENBRUCH_LOG_DIR=/workspace/runtime/e4-complete ./tools/check.sh --long`. **179 existing/E1 + 404 mutations + 103 rift/elite/boss + 111 reactions = 797 PASS / 0 FAIL**. Import clean; no script errors, error lines or leaked instances. Logs in test-results/. Graphical `tests/reaction_visual_runner.gd` rendered and inspected all four reactions plus actual result damage at 1280×720; E3 captures cover 1600×900 and 1920×1080. Only known llvmpipe VSync warning.

Final full-run fixture: **30:00**, one victory, three runes, 26,502 kills, 24 affixed elites, six Phase II transitions across the three boss kinds, two stabilizations/two overcharges, peak/final instability 94.7. **17,847 reactions**, all four types (6,186 Void Shatter / 2,529 Arc Freeze / 7,918 Blightburst / 1,214 Rift Conduction); 372,579.89 actual reaction damage, 96.523 s CPU wall time.

Final stress: 180 simulated seconds / 5,400 steps, three Phase II bosses and affixed elites at Critical instability; peaks **382 enemies / 261 shots / 300 pickups**; 12,665 kills, 7,200 bounded reaction events, 50.230 s wall time, no cap or runtime failures. Immunity/automatic movement/choices are explicit harness aids. No claim of real GPU frame rate, physical controller testing or a human thirty-minute balance pass.

Next concrete phase: **E5**, specification section 7. Implement the exact eighteen Star Map nodes, three prerequisite chains and listed costs/effects, capped Starlight finish awards, rollback-safe persistent purchases and controller-accessible scrollable Star Map. Apply purchased bonuses through the existing next-run constellation snapshot, never mutate an active run. Save migration/reset foundation already exists; preserve all 797 tests. Test/commit/push E5 separately, then E6 subtle feedback, complete result statistics and spoiler-safe Build Details. Do not recreate any existing systems.

## Phase E3 — implemented and verified; E4–E6 remain open

Implementation commit: `aee0e53`; pushed to GitHub main and independently verified by ls-remote and a fresh bare clone (project.godot plus all three E3 helpers present).

- Active 0–100 instability uses run_delta; five reversible factors apply once to existing wave/curse/pacing. Boss/elite gold only; once-per-run Unstable warning and English HUD/pause/result values.
- Four safe proximity-only rifts at 06/12/18/24 minutes, 90-run-second expiry, F/controller Y, exactly-once healing/gold/XP choices through the paused modal FIFO after mutations. Crowded placements retry within the original slot only.
- Seven affixes implemented in scripts/elite_affixes.gd, validated in Registry: actual armor, Swift cap, delayed Volatile blast, successful-contact-only Vampiric cooldown, warned safe Blinking, bounded Hexbound shots, fire-suppressed Regenerating. Director starts at minute five, respects current waves/caps and excludes splitters/children/bosses. Pooled state/reward duplication protected; encountered affixes ranked by actual counts.
- scripts/boss_patterns.gd separates HP phase, pattern step and timers. One half-HP transition, fixed warned Guardian dashes/starfalls; Queen curved bolts/six children/four null zones; Storm alternating safe-gap rings/three beams. Existing thirty waves, boss counts, chest spawn-time eligibility and all mutations/evolutions/fusions preserved.
- English instability/interaction HUD, orange warning markers, elite rings/affix symbols, blink destination and Phase II boss label. Pacing and save schema unchanged.

Validation: pinned Godot 4.7.2 Stable, tools/check.sh --long: **179 existing/E1 + 404 mutations + 99 E3 = 682 PASS, zero FAIL**, clean import, no script errors/leaks. Logs in test-results/.

Final 30-minute fixture: 30:00, one victory, three runes, 26,550 kills, 23 affixed elites, six boss phase transitions across all three kinds, two stabilizations/two overcharges, peak/final instability 94.2, 92.759 s CPU wall time. Real damage/evolution/choice APIs; immunity/automatic movement/choices are harness aids. No human balance claim.

Extended stress: 180 simulated seconds / 5,400 steps, Critical instability, three Phase II bosses and multiple affixed elites; peaks 382 enemies / 261 shots / 300 pickups; 12,396 kills, 46.838 s wall time. No cap/error failures. These timings do not establish rendered FPS.

Graphical smoke: actual rift marker at 1280×720, choice/focus at 1600×900, Phase II transition/HUD at 1920×1080; screenshots inspected in docs/screenshots/. Only known software-driver VSync warning. Physical controller, target GPU/frame pacing and human fresh-save difficulty remain manual checks.

Next: E4, exact four bidirectional element reactions from specification section 6. Use actual final triggering-hit damage, enemy timestamp/cooldown reset, shared 40-events/second cap, priority order and reaction-only proc source. Preserve all E1/E2/E3 checks and publish E4 separately after verification. E5 Star Map and E6 full statistics/build/feedback remain unfinished.

## Phase E2 — implemented; E3–E6 remain open

E2 implementation commit: `5ab1f7e`.

- 45 typed mutation definitions in resources/mutations, separate reproducible tools/generate_mutations.py, validated in the existing Registry.
- Model owns pending choices and runtime imprints; Lv4 requests exactly once, app inserts mandatory three-card choices before pending modals. Debug F11 requests missing mutations. No additional inventory slots or alteration of normal offers/charges.
- Shared Combat mutation helper implements parameter/attack/hit/periodic/contact/expiry processors, real bounded secondary hits/projectiles/mines/zones, per-impact/tick counters, status durations, deterministic Echo cadence and recursion protection.
- All 15 normal evolutions retain full imprints; both fusions retain primary 100% and secondary 50%. Old owners removed, catalysts and slot behavior preserved. Recipe spoilers remain hidden until actual evolution.
- Pause/build displays mutated, evolved/inherited and fusion Primary/Echo identities. Renderer inspected at 1280×720, 1600×900 and 1920×1080. HUD keeps its compact layout.
- Pacing resource unchanged. Charged Air applies a visible electric status; actual reactions await E4.

Validation: Godot 4.7.2 via tools/check.sh; 179 existing/E1 checks plus 404 mutation checks = **583 PASS, zero FAIL**, no script errors/leak reports. Mutation suite tests all 45 base/evolved effects, full inheritance, both fusions with neither/one/both imprints, integer Echo cadence, AoE-event debouncing, immutable resources and the mandatory modal queue.

Full-run fixture uses six mutations inherited through real evolutions: 30:00, one victory, three runes, 23,862 kills, 82.835 s wall time. Stress fixture likewise uses inherited mutations: 180 simulated seconds, 380 enemies / 261 projectiles / 300 pickups, 11,356 kills, 43.232 s wall time. These are CPU simulations with immunity/automatic choices, not human balance or rendered FPS claims.

Graphical E2 smoke: actual selection at 1280×720, inherited evolution at 1600×900, both fusion imprints at 1920×1080. Screenshots inspected; only known software-driver VSync warning. No physical controller/hardware FPS claim.

Next concrete phase: E3. Activate existing rift_state with run_delta, HUD and cumulative director/contact/reward factors. Add four proximity-only timed rift slots with F/gamepad interaction through the same modal queue. Add bounded elite director with seven affixes and genuine eligible rewards. Give each existing boss a separate boss_hp_phase and independent attack-pattern state with the exact telegraphs from the specification. Do not implement E4/E5 before E3 is tested/committed/pushed.

## Phase E1 — completed foundation

The uploaded Phase E specification is preserved as NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md. Full scope and exact continuation ledger: docs/FEATURES_PHASE_E.md.

Files: scripts/run_statistics.gd (real hit/health accounting, fixed DPS buckets), scripts/rift_instability.gd (tested state/bands), scripts/data/element_tags.gd (neutral/base/evolution/fusion tags), run_model.gd (run_delta and runtime ownership), world.gd (real damage/crit accounting), save_manager.gd (additive Starlight/node defaults and validation), app.gd (next-run constellation snapshot), registry.gd and tests/test_runner.gd.

E1 implementation commit: `9737363`.

Validation: Godot 4.7.2 Stable via tools/check.sh, 179 PASS / 0 FAIL, clean import, no script errors/leak reports. Existing gameplay/menu/evolution/save regression checks remain active. New migration tests preserve old gold, meta, recipes and settings; reset clears new fields. Pacing resource is unchanged.

Full-run regression with E1: 30:00, one victory, three runes, 23,923 kills, 76.527 s wall time, no script errors/leak reports. See test-results/full-run.log.

At the E1 checkpoint the next task was E2 (now completed above). Add the 45 exact mutation definitions from the uploaded table; implement shared bounded hooks and inheritance before exposing mutation UI. Mutation choices must be inserted immediately after the level-up that reached Lv4; do not append behind already queued level-ups. Ordinary evolutions inherit 100%; fusion bases[0]/bases[1] inherit 100%/50%, with deterministic every-other-trigger handling for quantized echoes. Do not leak undiscovered recipes.

Still pending after E2: active instability/director/rift nodes, affix elites, new boss phases, reactions, Star Map purchases/bonuses/currency awards, expanded result/build UI and E3–E6 graphical captures. E2 mutation/evolution/fusion captures are complete. No full expansion completion claim.

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
