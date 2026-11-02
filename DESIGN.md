# Architecture

- Typed Resource subclasses in `scripts/data/`; immutable definitions in `resources/`. Registry validates IDs, positive values, waves and recipe dependencies. Runtime weapon values are deep copies.
- `run_model.gd`: XP overflow, weighted legal offers, stats, equipment, runes and evolution thresholds. Timed speed bonuses are derived from run time rather than incrementally multiplied.
- `combat.gd`: separate real attack algorithms. Added ricochet targeting, armed proximity mines and weakest-target execution attacks.
- `world.gd`: manual enemy/pickup/projectile pools, spatial hash, segment collision, statuses, director, boss attacks and procedural drawing. New retaliation and wounded-target passive hooks use the normal damage system.
- `player.gd`: CharacterBody2D, floating movement and Camera2D. The arrow geometry rotates around its own center; neither the camera nor movement/collision coordinates rotate. There is no direction-indicator dot.
- `app.gd`: real menu Controls, FIFO level/rune/chest modals and paused world. Collection entries are revealed from persisted acquisition/selection events, not from unlocked status or viewing offers.
- `window_settings.gd`: window mutations only on display changes; `Engine.is_embedded_in_editor()` detects native editor embedding, because consumed `--wid` arguments are not reliably present in `OS.get_cmdline_args()`. Embedded and headless runs never request native resizing. Standalone window sizes are verified graphically.
- `save_manager.gd`: defaults, schema checks, corrupt-save backup, atomic writes, meta shop and unlocks. Old save data is preserved and new weapons are merged into existing pools.
- `audio_manager.gd`: original synthesized ambient loop and effects, separate music/effects buses. Audio settings do not call native window APIs.

Spatial hash cells are 96 px. Enemy collisions use circles; projectiles and beams use exact segment distances after a broadphase query. Pools reset mutable dictionaries on reuse. Normal world nodes pause with SceneTree; UI and audio remain responsive. Proc-tagged damage does not recursively generate new procs.

Art is deliberately geometric and original. Stages use repeating coordinate-stable procedural decoration without blocking obstacles. Menus are built in one controller instead of empty per-page scenes. Three entry scenes exist: main menu, arena and player. Chests have a short skippable fade and grant real rewards immediately.

Validation uses isolated functional tests, a sustained CPU load fixture, a full accelerated 30-minute simulation and graphical smoke tests. Load fixtures give immunity and automated choices, so they do not prove human winability. Mesa software rendering and synthetic controller events do not establish target-hardware FPS or physical controller compatibility.

## Phase E work in progress

E1 provides tested save/runtime/statistics foundations; E2 implements all 45 weapon mutations and evolution/fusion inheritance. E3–E6 remain pending. See `docs/FEATURES_PHASE_E.md` and `STATUS.md` for the exact continuation point.

## E2 mutation integration

`mutation_effects.gd` is a helper owned by the existing Combat object, not a second combat engine. Shared parameter, attack, hit, contact, periodic and expiry hooks cover normal/evolved/fused behaviors. For altered attack types, additional projectiles map to bounded pulses. Runtime owners change at evolution; immutable Resources and inventory slot counts do not change.

Model mutation requests are independent of normal level offers. App inserts pending mutation modals before already queued level/chest/rune events, preserves FIFO among mutation requests and never exposes a cancel/skip path. High-level debug setup explicitly calls `ensure_mutations`. Unrevealed recipe privacy remains based solely on successful evolutions saved in `evolved_recipes`.

### E3 implementation

`rift_nodes.gd`, `elite_affixes.gd` and `boss_patterns.gd` are bounded helpers owned by the existing World. They use its pools, damage pipeline, projectiles, hazards and seeded model RNG. Rift decisions enter the existing paused queue after mutations and before other pending events. Boss HP phase is separate from the original charger `phase`. Instability is current derived pressure, not repeated mutation of enemy resources. All new pooled fields are initialized in `spawn_enemy`; death is protected by World membership. Saves and existing inventory/evolution rules are unchanged.

### E4 implementation

`element_reactions.gd` is owned by World and shares its hit pipeline, spatial hash and actual combat clock. It caches immutable base/evolved/fusion tags, checks previous per-enemy history in fixed priority order, then updates this hit's actual tags. Mutation `on_hit` returns successfully applied elements; no UI-created status or inferred inventory-only reaction is used. `proc=true` forbids reaction reentry and mutation recursion. Reaction damage records one source in RunStatistics and the result UI. Per-status DoT attribution keeps reaction Burn out of normal weapon totals, with no duplicate ticks. Global integer-second event budget and local cooldown are independent; visuals/candidates are bounded and pooled state is reset.
