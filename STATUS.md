# STERNENBRUCH — continuation status

Engine requirement: **Godot 4.7.2 Stable**, GDScript 2.0. Original brief preserved in `CODEX_MASTERPROMPT.md`; the latest user-requested English, progression and evolution changes override its earlier language/balance requirements.

## Maintenance M5 — complete; M1–M5 accepted (2026-11-03)

All five maintenance phases are complete in the existing project. Published phase commits: M1 `a3222a5`, M2 `9f5b4b6`, M3 `cebf835`, M4 `b7ee0dc`; M5 is the commit containing this section. Full changes, evidence, limits and follow-ups: [maintenance report](docs/MAINTENANCE_REPORT.md). Older continuation instructions below are historical.

Final safety fixes: failed reward saves now prevent Main Menu/Try Again from discarding the unbanked Model, retry before navigating and bank once after recovery. Quit retries pending discovery/settings and stays on an explicit storage-error page if still blocked. Forced termination/crash cannot preserve RAM-only progress on an unwritable disk. No save schema/version changes. A graphical movement fixture now waits until its final physics tick finishes before measuring; distance assertions remain intact.

Final Godot **4.7.2.stable.official.ed1daf0bf**: **1009 functional PASS / 0 FAIL** (976 original + 33 maintenance), **7 Python generator tests**, clean import/parser. Five earlier isolated seeds 1/42/115/72047/115 each pass 179 unit checks. Native graphical suite: **45 assertions**, real embedded host: **8 assertions**, plus captures for mutation/rift/reaction screens at three resolutions. All final logs are free of engine errors/leaks; only the software-driver VSync warning remains. Read-only rendering passes actual draw checks; M4 pixel oracle passed four assertions against the pre-extraction implementation. Pending-result 1280 and renderer captures inspected.

Normal full simulation: 30:00 / 1800 combat seconds, 26,343 kills, 23 elites, six boss phase transitions, 18,490 reactions, one victory; 101.709 s CPU wall time. Quick: same 30:00 schedule / 900 combat seconds, 13,013 kills, 22 elites, six phase transitions, 8,809 reactions, one victory; 50.629 s. Both logs match baseline c0a6fc7 exactly apart from wall time. Stress: 5400 steps / 180 simulated seconds, peaks 382 enemies / 261 projectiles / 300 pickups, 12,585 kills, 7,186 reactions; 51.381 s.

Legacy-save migration and corruption/reload tests pass. All 153 catalog resources and nine generated scripts match staged generator outputs; every resource and project setting is unchanged versus c0a6fc7. No gameplay/balance/pace changes. App remains lifecycle owner; only Collection was extracted. World simulation/hits/pools/feedback timers remain authoritative; only drawing was extracted. Larger UI/damage/entity-schema changes and generator source migration remain separate future tasks. Physical devices, audible checks, desktop DPI/GPU performance, release export and human balance are not claimed tested.

Evidence: current test-results/*.log, maintenance-audit.log, maintenance-seeds.log, render-m4.log and docs/screenshots/. Final publication must be verified with a fresh remote ref/tree; the published M5 hash is reported in the final response.

## Maintenance M4 — complete; M5 acceptance next

Published: M1 a3222a5, M2 9f5b4b6, M3 cebf835. World drawing now delegates to scripts/world_renderer.gd through one synchronous borrowed render-view dictionary. Renderer stores no view/entity references, schedules no effects and calls no simulation methods. World retains authoritative simulation, hit/death/drop order, pools, spatial hash and feedback scheduling/camera decay. No combat or damage-engine rewrite. World reduced from 602 to 510 lines; the extracted renderer is 116 lines.

Validation: 1004 Godot checks + seven generator tests pass. Real SubViewport rendering preserves all snapshotted gameplay/RNG/pool/stat/cadence data. A temporary pre-M4 _draw reference recovered from commit 9f5b4b6 (outside repo) renders **pixel-identically**, with identical runtime snapshots: four graphical assertions passed. Permanent render_readonly_runner covers real output and read-only state, and is part of graphical_check.sh. No engine errors/leaks; only known VSync warning. test-results/render-m4.log.

Intentionally deferred: splitting damage/AI/pools or moving feedback update ownership; those would need broader lifecycle contracts and offer no necessary benefit here. M5 next: complete normal/Quick simulations, stress, all suites, multi-seed fixture runs, all native/embedded UI checks and final diff/data verification.

## Maintenance M3 — complete; M4/M5 next

Published prior phases: M1 a3222a5, M2 9f5b4b6. Affix/reaction constants now live in pure scripts/data/elite_affix_definitions.gd and element_reaction_definitions.gd. Registry imports only pure data; gameplay keeps compatible DEFINITIONS aliases pointing to the exact same objects. Values/IDs/behavior unchanged; no cycles or second data source introduced.

Safe tools/check_generated.py stages both existing generators outside the project, checks stable catalog IDs via tools/catalog_ids.json and exact file sets/bytes (153 resources + nine generated scripts). It has no apply mode. Seven Python tests prove no writes and detect numeric/ID/missing/extra/script drift plus generator errors. docs/GENERATORS.md explicitly lists all overwritten paths and remaining mutation-brief coupling. No generator was applied to production resources.

Validation: **1004 Godot functional PASS / 0 FAIL**, seven Python safety tests pass and staging generation is byte-identical. Three new maintenance tests confirm shared data identity and Registry validation. No script errors/leaks; no balance/resource diff. Logs: test-results/maintenance-m3.log. Next M4: extract drawing only with render-state immutability/pixel comparison; keep combat/update/feedback timing in World. Then full M5 acceptance.

## Maintenance M2 — complete; M3–M5 next

M1 commit a3222a5 is published. Extracted exactly one view: scripts/ui/collection_view.gd. App still owns navigation, Back callback, session/pause and modal state; the component receives only Registry and a discovery-query Callable, owns no save/model and preserves original labels, ordering and scroll dimensions. No redesign or second state machine. Other views remain in App deliberately.

Validation: **1001 functional PASS / 0 FAIL** (976 original + 25 maintenance). Three new component contracts verify hidden entries, completed-only recipes and read-only rendering. Full native graphical suite passes plus 15 new maintenance visual assertions: Collection hidden/known, purchase failure/unchanged wallet and pending-progress pause/focus/retry at 1280×720, 1600×900 and 1920×1080. Existing mutation/rift/build/Star Map/window/input captures pass; Collection 1280 capture inspected. Only known software VSync warning. No script errors/leaks. test-results/maintenance-m2.log and maintenance-visual.log.

Next M3: extract pure affix/reaction definitions, retain helper constant aliases and build a safe staging-only generator check. M4 only drawing extraction, not simulation rewrite; M5 full acceptance after all changes.

## Maintenance M1 — implemented and tested; M2–M5 next

Fixed discovery test isolation without changing gameplay randomness: the modal fixture has a controlled optional STERNENBRUCH_TEST_SEED, and discovery assertions use their own fresh SaveManager. Five isolated unit runs (seeds 1, 42, 115, 72047, 115) each passed all 179 checks.

SaveManager now handles open/write/rename failure centrally, restores purchase/reset/finish snapshots consistently, and keeps already-earned discovery/settings changes explicitly pending in memory until a successful retry. Meta buy no longer reports success on failed storage. Atomic file replacement, version 1 and all data fields are preserved. App avoids duplicate inventory writes and exposes errors/retry in menu/shop/settings/pause/stage selection plus a calm gameplay notice. Pending retry receives focus; it never advances/resumes a paused run.

Validation: 976 preserved functional checks pass plus 22 new maintenance checks = **998 PASS / 0 FAIL**. Real file-open obstruction and nonempty-directory rename failure are exercised, including preservation of the old file, rollback, retry/reload and UI focus. No script errors/leaks. Logs: test-results/maintenance-m1.log. Code/resources/pacing/weapon/boss numbers unchanged.

Next: M2 extract exactly Collection/Bestiary with explicit read/callback interfaces; M3 pure definitions and safe generator checks; M4 bounded rendering-only extraction if safe; M5 complete long/Quick/stress/graphical acceptance. Each phase must be tested and published separately. Earlier architecture findings below are historical; M1 discovery/meta-save issues are now fixed.

## Maintenance documentation — AGENTS and architecture review

Code baseline: `26b5b4e` (E1–E6). Added root AGENTS.md as the concise Codex entry point and docs/ARCHITECTURE_REVIEW.md with incremental recommendations. README/DESIGN link them; SMOKE_TEST removes one obsolete “pending E2–E6” sentence. Only Markdown changes: no runtime/test/generator/resource changes, balance adjustments, refactors or removed features.

Findings: App (757 lines) and World (602) combine multiple responsibilities; runtime dictionaries and World/helper access are implicit contracts; Registry imports data from gameplay helpers; generator/save/unlock assumptions are distributed. Legacy meta buy() ignores write failure, unlike transactional Star Map purchases. These are documented follow-up tasks, not implemented changes.

Verification this session: Godot 4.7.2 Stable via tools/check.sh. First attempt: 178 base checks passed, one existing discovery assertion failed, so the script correctly stopped. A full rerun in fresh isolated XDG directories passed **976 / 976**, with no script errors/leaks. Investigation confirmed an existing flaky fixture: an earlier random choose(0) can select Prism Disc, but a later assertion expects it unselected. A temporary diagnostic copy outside the repo reproduces exactly this false failure with RNG seed 115 before the first LEVELUP offer. Actual acquisition correctly reveals the entry; game and repository tests were not modified. Fresh XDG directories alone do not fix this within-run random dependency. Prioritize fixture isolation in a future task.

Documentation validation passed: 17 relative Markdown links across six changed documents, 15 explicit project paths in AGENTS, shell syntax of both check scripts and the AGENTS command block, and git diff --check. No new stress, thirty-minute or graphical runs were required for Markdown-only edits; E6 results below remain historical evidence, not tests newly executed by this task. Architecture review follow-ups are explicitly still open.

## Phase E6 — complete; E1–E6 final acceptance passed

E5 implementation/publication: **5e474ca**. E6 implementation/publication: **8eda910**, verified by ls-remote plus a fresh bare clone containing the actual project, new helpers, final report and unchanged catalog counts. Final detailed report: docs/FINAL_REPORT_PHASE_E.md. Older sections below are historical checkpoints; their continuation instructions are superseded by this section.

All requested E1–E6 systems are implemented in the existing project. No recreation, removed catalog items, reset of valid saves, force-push or changes to resources/pacing.tres. English UI remains intact.

E6 files: scripts/run_report.gd, run_statistics.gd, run_model.gd, app.gd, world.gd, player.gd, combat.gd; mutation_effects.gd/element_reactions.gd carry inherited target factors to keep situational stars exact across secondary recipients. SaveManager preserves mid-run unlocks and transactional finish behavior; Star Map scales its connected canvas at larger UI scale.

- Complete real statistics: actual damage by source, shares, combat DPS, highest critical/single hit and ten-second DPS; damage taken/healing, XP/gold, actual upgrade/mutation/evolution/fusion events, bosses/elites, instability/rifts, achievements and Starlight. No overkill/overheal inflation or duplicated rewards.
- Build Details: all six-plus-six slots, behaviors/levels, inherited mutation descriptions/Primary/Echo, hero/rune/meta/star bonuses, final values, temporary durations and elements/reactions. Only actually discovered evolution recipes expose names/requirements/readiness. Inspection never advances time, rolls cards or grants XP.
- Fixed result/Build actions stay visible while scrolling. Save failure shows Pending rewards plus a fixed controller-accessible Retry Saving action. Both victory/defeat and Try Again are tested.
- Calm feedback: enemy flash <=0.06 s, player <=0.07 s, no normal-hit shake, capped deterministic boss-hit/death motion <=1.5/2 px for <=0.07/0.10 s, immediate zero offset when disabled, readable capped critical numbers and bounded impact FX. No feedback RNG consumption.
- Final math/regression fixes: actual damage still counts as a successful contact when Last Star heals above the preceding HP; weapon retaliation/death-fire retain attribution without secondary recursion; flat hero bonuses are displayed correctly; fresh/derived secondary star bonuses apply exactly once and cannot leak to ineligible recipients.

Godot **4.7.2.stable.official.ed1daf0bf**. Final command: `STERNENBRUCH_LOG_DIR=/workspace/runtime/e6-correct-final ./tools/check.sh --long`. **179 existing/E1 + 404 mutations + 103 rift/elite/boss + 111 reactions + 90 constellations + 40 polish + 49 whole-catalog = 976 PASS / 0 FAIL**. Clean import, no script/runtime errors or leaked instances. test-results/ contains final logs.

Normal simulation: every step through **30:00 / 1800 combat seconds**, one victory, three runes, 26,343 kills, 23 affixed elites, six boss Phase II transitions, two stabilizations/two overcharges, all eighteen stars, peak/final instability 91.2, 18,490 reactions across all four kinds. Eight Starlight banked exactly once; measured source rows reconcile. Total damage 10,861,180.39; average combat DPS 6,033.99; highest critical 132; **101.867 s CPU wall time**.

Quick simulation on final code: **30:00 / 900 combat seconds**, one victory, three runes, 13,013 kills, 22 affixed elites, six transitions, two/two rifts, all eighteen stars, 8,809 reactions, eight Starlight once; **50.902 s CPU wall time**. Separate quick-run.log.

Final stress: **180 simulated seconds / 5,400 steps**, three Phase II bosses, elites, inherited mutations and all stars; peaks **382 enemies / 261 projectiles / 300 pickups**; 12,585 kills, 7,186 bounded reactions; **50.294 s wall time**, no cap/runtime failures.

Graphical: native 1280×720 / 1600×900 / 1920×1080, UI scale 1.2, original menus/input, all phase UI captures, four character starts, scrolling and fixed actions. Real --wid embedding: controller action navigates stars, Build/results work, audio/display settings produce no native resize requests or resize spam. **33 graphical/input PASS**, no failures; screenshots inspected. Only known llvmpipe VSync warning. UI screenshot fixtures are scripted state captures, distinct from per-step full simulations.

Simulation harness immunity/automatic movement/choices are explicit test aids. Remaining manual/platform checks: physical controller, real editor/desktop focus/DPI/fullscreen, audible balancing, target GPU frame pacing, human fresh/progressed-save thirty-minute difficulty and native release exports. No such hardware/human claims are made. No known unresolved script/runtime/test failures remain.

Continuation: no E phase remains to implement. Preserve this checkpoint; future work should address the manual/platform checks or new user requests. Reproduce tests using tools/check.sh --long; graphical checks via DISPLAY=:99 tools/graphical_check.sh and --wid <decimal-X11-host-ID>. All gameplay content/recipe gates/save compatibility remain protected by the regression suites.

## Phase E5 — complete and tested; E6 next

Implementation commit: `5e474ca` (published and verified). Data: scripts/data/constellations.gd; interactive connected three-branch Star Map: scripts/star_map.gd and app.gd. All eighteen specified nodes/costs/prerequisites and real combat/stat/rift/timed hooks are implemented. Total cost 63 Starlight; rewards capped at eight, booked exactly once at finish. Save failures roll back both purchases and finish rewards and expose a retry message. Existing version-1 saves/migration/reset retained; active runs use independent snapshots. No changes to opening pacing or mutation/evolution gates.

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
