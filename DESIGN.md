# Architecture

- Typed Resource subclasses in `scripts/data/`; immutable definitions in `resources/`. Registry validates IDs, positive values, waves and recipe dependencies. Runtime weapon values are deep copies.
- `run_model.gd`: XP overflow, weighted legal offers, stats, equipment, runes and evolution thresholds. Timed speed bonuses are derived from run time rather than incrementally multiplied.
- `combat.gd`: separate real attack algorithms. Added ricochet targeting, armed proximity mines and weakest-target execution attacks.
- `world.gd`: manual enemy/pickup/projectile pools, spatial hash, segment collision, statuses, director, boss attacks; synchronous read-only procedural drawing lives in `world_renderer.gd`. New retaliation and wounded-target passive hooks use the normal damage system.
- `player.gd`: CharacterBody2D, floating movement and Camera2D. The arrow geometry rotates around its own center; neither the camera nor movement/collision coordinates rotate. There is no direction-indicator dot.
- `app.gd`: real menu Controls, FIFO level/rune/chest modals and paused world. Collection entries are revealed from persisted acquisition/selection events, not from unlocked status or viewing offers.
- `window_settings.gd`: window mutations only on display changes; `Engine.is_embedded_in_editor()` detects native editor embedding, because consumed `--wid` arguments are not reliably present in `OS.get_cmdline_args()`. Embedded and headless runs never request native resizing. Standalone window sizes are verified graphically.
- `save_manager.gd`: defaults, schema checks, corrupt-save backup, atomic writes, meta shop and unlocks. Old save data is preserved and new weapons are merged into existing pools.
- `audio_manager.gd`: original synthesized ambient loop and effects, separate music/effects buses. Audio settings do not call native window APIs.

Spatial hash cells are 96 px. Enemy collisions use circles; projectiles and beams use exact segment distances after a broadphase query. Pools reset mutable dictionaries on reuse. Normal world nodes pause with SceneTree; UI and audio remain responsive. Proc-tagged damage does not recursively generate new procs.

Art is deliberately geometric and original. Stages use repeating coordinate-stable procedural decoration without blocking obstacles. App owns menu navigation and lifecycle; the presentation-only Collection component receives a discovery callback instead of session/save ownership. Three entry scenes exist: main menu, arena and player. Chests have a short skippable fade and grant real rewards immediately.

Validation uses isolated functional tests, a sustained CPU load fixture, a full accelerated 30-minute simulation and graphical smoke tests. Load fixtures give immunity and automated choices, so they do not prove human winability. Mesa software rendering and synthetic controller events do not establish target-hardware FPS or physical controller compatibility.

## Phase E — complete

E1–E6 are implemented and tested: mutations/inheritance, active rifts and phased bosses, elemental reactions, permanent Star Map, measured results and spoiler-safe Build Details. See `docs/FINAL_REPORT_PHASE_E.md` for complete regression evidence and remaining hardware/manual checks.

## E2 mutation integration

`mutation_effects.gd` is a helper owned by the existing Combat object, not a second combat engine. Shared parameter, attack, hit, contact, periodic and expiry hooks cover normal/evolved/fused behaviors. For altered attack types, additional projectiles map to bounded pulses. Runtime owners change at evolution; immutable Resources and inventory slot counts do not change.

Model mutation requests are independent of normal level offers. App inserts pending mutation modals before already queued level/chest/rune events, preserves FIFO among mutation requests and never exposes a cancel/skip path. High-level debug setup explicitly calls `ensure_mutations`. Unrevealed recipe privacy remains based solely on successful evolutions saved in `evolved_recipes`.

### E3 implementation

`rift_nodes.gd`, `elite_affixes.gd` and `boss_patterns.gd` are bounded helpers owned by the existing World. They use its pools, damage pipeline, projectiles, hazards and seeded model RNG. Rift decisions enter the existing paused queue after mutations and before other pending events. Boss HP phase is separate from the original charger `phase`. Instability is current derived pressure, not repeated mutation of enemy resources. All new pooled fields are initialized in `spawn_enemy`; death is protected by World membership. Saves and existing inventory/evolution rules are unchanged.

### E4 implementation

`element_reactions.gd` is owned by World and shares its hit pipeline, spatial hash and actual combat clock. It caches immutable base/evolved/fusion tags, checks previous per-enemy history in fixed priority order, then updates this hit's actual tags. Mutation `on_hit` returns successfully applied elements; no UI-created status or inferred inventory-only reaction is used. `proc=true` forbids reaction reentry and mutation recursion. Reaction damage records one source in RunStatistics and the result UI. Per-status DoT attribution keeps reaction Burn out of normal weapon totals, with no duplicate ticks. Global integer-second event budget and local cooldown are independent; visuals/candidates are bounded and pooled state is reset.

## E5 Star Map

Constellations are separately maintained immutable data, validated by Registry and untouched by catalog generators. Star Map uses real focusable nodes, explicit directional links and drawn prerequisite connections. SaveManager transactions roll back on write failures; finish banking is set only after a successful atomic save. Model snapshots own purchased nodes; stats derive bonuses once, timed effects use run boundaries/deadlines and situational damage hooks stay in World.

## E6 reports and feedback

RunStatistics records actual capped damage, highest critical hit, XP credited, gold pickups and successful upgrade/mutation/evolution/fusion events. Its eleven second buckets use active combat time, preserving meaningful Quick Mode DPS. RunReport only projects current state/measured events; opening it never ticks, rolls offers or recalculates bonuses. Base/evolution/fusion IDs stay separate; secondary mutation hits retain weapon ownership, reaction/DoT damage stays in its own source. Death-fire and Blood Thorns retaliation retain correct weapon IDs and proc guards.

App builds fixed-action detail pages outside the scroll area. Build Details uses the live model snapshot and explicit completed-recipe discovery, including known requirement readiness; it never infers secret recipes from component ownership. Mid-run unlock events are retained through finish. Failed reward saves roll back and expose a retry action; pending rewards are labeled honestly.

Feedback never consumes gameplay RNG: short desaturated local flashes, capped critical impacts/text, deterministic length-bounded camera decay. Ordinary damage produces no shake. Screen Shake off clears camera offset immediately even during paused settings. New Star Map content scales inside its own canvas for the 1.2 UI-scale setting without losing constellation nodes.

## Maintenance guidance

[AGENTS.md](AGENTS.md) is the concise Codex entry point. The [architecture review](docs/ARCHITECTURE_REVIEW.md) records responsibility hotspots, dependency risks and a proposed incremental order; it does not authorize or perform refactoring.

## M1 persistence maintenance

SaveManager centralizes write failures and commit/rollback for meta/star purchases, reset and run finish. Earned discovery/settings changes remain pending in RAM on failure, with explicit UI feedback and retry; transactional failures restore both prior data and prior pending status. Retry clears errors only after successful storage. Inventory/unlock recording shares one write where possible. Test fixture randomness is controlled independently of normal randomized gameplay.

## M2 Collection component

`ui/collection_view.gd` is a read-only ScrollContainer. `populate(registry, discovered)` receives an explicit query callback rather than SaveManager or App. App constructs the original page/header and Back/error controls and retains all navigation/session state. Similar presentation-only views may be extracted later, one at a time; Settings is intentionally not changed because it owns live native-display/audio callbacks.

## M3 data boundaries

Registry and gameplay share pure `data/elite_affix_definitions.gd` / `data/element_reaction_definitions.gd`; helper aliases preserve callers without duplicated constants. Safe generator checks run in disposable trees, validate explicit stable-ID baselines and compare every owned output byte without writing the project. Detailed ownership and the remaining positional Markdown input dependency are documented in docs/GENERATORS.md.

## M4 rendering boundary

World passes a bounded, synchronous borrowed view to `world_renderer.gd`. Canvas commands remain inside the World draw notification; no per-frame deep state copies, retained pooled references or second simulation exist. The renderer may only read its view and use non-advancing mutation parameters. Model/FX/AI updates, hits, rewards and feedback timers retain their original World order. State immutability is tested on real draw frames; a one-time pre-extraction pixel oracle also passed.

## M5 acceptance and navigation safety

Result navigation retries unbanked rewards before releasing the run; failed retries keep the original paused Model and fixed actions. Main-menu Quit similarly refuses a failed pending-write retry and offers Back/Retry without a second state owner. Pending state is session-only, not a new save field; an unwritable disk cannot guarantee survival of forced termination. All catalog/balance inputs are unchanged. Normal and Quick simulation logs match the pre-maintenance baseline apart from wall time. See [maintenance acceptance](docs/MAINTENANCE_REPORT.md).

## Explicit selections, recipe queries and Settings origin

Star Map uses pressed for committed selection and theme normal/hover styles for a persistent constellation-colored border; focus draws a separate inset ring. SaveManager.star_purchase_error is read-only and leaves global technical warnings/pending writes untouched. The inspector owns expected purchase hints, so exiting the map destroys them. Existing atomic buy/retry operations remain authoritative.

RunModel.recipe_matches is the read-only equipped-component/level query shared by Pause reporting and chest evolution. UI counts each recipe once, hides undiscovered details and reports ready independently of the unchanged eligible-chest rule. Already evolved weapons cannot supply consumed bases. Settings uses its own SETTINGS state and the existing return_to_pause origin; leave_settings restores Pause/menu, never resumes a run. Explicit controller UI bindings ensure A/B/D-pad/stick reach standard Control focus/pressed handling.

The separate pacing resource now stores player_speed=0.7125 and player_damage=0.93. RunModel applies damage through one raw-value helper, including Might; World only uses it when creating fixed raw effects, never when processing hit-derived secondary values. Details and rounded-damage limits are in BALANCE.md; current acceptance evidence is in docs/UI_BALANCE_REPORT.md.

Day/Night’s legacy orbit-to-beam conversion retains its existing Might bonus formula. A damage_has_global_factor marker excludes the new global factor from the second parameterization, so the fusion receives exactly one 0.93 reduction. Raw Blood Thorns reflection and pickup Nova use the same Model helper as other fixed sources.

## UI text style

English UI uses short labels and contextual help. Pause keeps equipment, recipe counts and rift status; Build Details retains discovered recipe requirements, chest eligibility, mutation effects and instability modifiers. Results retain measured statistics, with damage attribution details in the Damage by Source tooltip. Star Map shows each prerequisite once and uses local purchase reasons; storage failures and retry remain separate. Display names may change (Veil); persistent IDs and gameplay values do not.
