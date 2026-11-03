# NULLBORN / STERNENBRUCH — Codex working rules

## Start here

- Use **Godot 4.7.2 Stable**, **GDScript 2.0**, Compatibility renderer only. Never Godot 3, C#, or a different engine version.
- Read the latest section of [STATUS.md](STATUS.md), then [README.md](README.md), [DESIGN.md](DESIGN.md) and relevant [BALANCE.md](BALANCE.md) rules. Older STATUS sections are historical checkpoints, not unfinished work.
- Inspect `git status --short`, recent commits, branches/remotes and the actual affected code/tests before editing. Current user instructions supersede historical briefs. E1–E6 already exist: **do not recreate working systems or start a replacement project**. Prefer a small extension/fix at the existing integration point; justify necessary refactors separately.
- Keep gameplay UI English. Preserve content, progression and the deliberate opening pace unless the task explicitly requires changing them. [Architecture review](docs/ARCHITECTURE_REVIEW.md) records follow-up recommendations, not permission to implement them automatically.

## Ownership and project map

| Path | Responsibility |
|---|---|
| `project.godot`, `scenes/` | Entry: `main_menu.tscn`; gameplay `game.tscn`; `player.tscn` |
| `resources/`, `scripts/data/registry.gd` | Typed immutable catalogs, IDs, dependency validation; separate `resources/pacing.tres` |
| `scripts/run_model.gd` | Authoritative run state, inventory, stats, offers, mutations/evolution, run clock and permanent-bonus snapshots |
| `scripts/world.gd`, `spatial_hash.gd` | Entity pools, hit pipeline, AI/update loop, collision, drops, hazards and procedural drawing |
| `scripts/combat.gd`, `mutation_effects.gd` | Existing attack behaviors and shared mutation hooks/budgets |
| `scripts/boss_patterns.gd`, `elite_affixes.gd`, `rift_nodes.gd`, `rift_instability.gd`, `element_reactions.gd` | Bounded helpers using the existing World/Model APIs |
| `scripts/app.gd` | UI/session orchestration, modal queue, pause, discovery and settings routing |
| `scripts/run_report.gd`, `run_statistics.gd` | Read-only reports; measured event counters, attribution and bounded DPS buckets |
| `scripts/star_map.gd`, `scripts/data/constellations.gd` | Connected constellation UI; permanent node definitions/prerequisites/costs |
| `scripts/save_manager.gd`, `window_settings.gd`, `audio_manager.gd`, `player.gd` | Persistence/unlocks; native-window isolation; audio; movement/facing |
| `tests/`, `tools/`, `test-results/`, `docs/` | Regression fixtures, generators/check scripts, recorded evidence and documentation |

## Extend content through existing systems

- Keep stable IDs. Runtime values must be copies (`duplicate(true)` where nested data changes); never mutate shared `.tres` definitions.
- `tools/generate_data.py` overwrites base catalogs **and data scripts**. Change its source alongside generated definitions. `tools/generate_mutations.py` is separate and currently parses the Phase E specification with fixed count/order assumptions; inspect it before regenerating. It does not protect hand edits. Do not run generators for unrelated changes.
- A new weapon needs coherent resource/generator data, Registry validation, offer/save-unlock migration, element tags, an existing or deliberately added attack behavior, mutation compatibility and tests. Definitions alone are not an implemented weapon.
- Each base weapon offers exactly three mutations once at Lv4, outside normal level-up cards. No slot cost, reroll/skip/banish or cancel path. Keep `ensure_mutations()`/`select_mutation()` and FIFO ordering, including overflow/debug setups.
- Evolution: base Lv5+, matching passive Lv5 and a chest from a boss **spawned** at 10:00+. Passives remain. Fusions take priority, replace both bases with one weapon and inherit recipe `bases[0]` at 100%, `bases[1]` as Echo 50%. Normal evolutions inherit 100%. Preserve adapted effects and deterministic fractional/cadence handling.
- Use shared parameter/attack/hit/contact/expiry hooks, the hit pipeline, seeded `model.rng`, pools and spatial hash. Keep `proc=true` recursion guards, damage-source/DoT ownership and inherited `target_factor` / `inherited_target_factor` propagation. Secondary damage must not double-apply conditional bonuses or transfer them to ineligible targets.
- Reset every new mutable field on pool reuse. Delayed effects snapshot values/IDs, never retain pooled enemy dictionaries. Keep existing entity, projectile, FX, text and reaction budgets; avoid unbounded per-hit histories or all-pairs scans.

## UI, time and calculation safety

- Model owns gameplay state; UI must not create duplicate inventories, reward counters or simulated stats. Reports/drawing must not advance timers, roll offers, advance mutation cadence or grant XP.
- Preserve modal state guards and pausing: mandatory mutations precede pending choices; rifts follow mutations before other pending events. Choosing a card/reward must happen once. Keep fixed Build/Result actions, focus navigation and 1280×720 / 1600×900 / 1920×1080 support.
- Collection discovery is actual acquisition/selection; recipe disclosure is only `evolved_recipes`, never component ownership, `seen`, mutations or Star Map purchases. Characters overview cannot start runs; retain the explicit reset confirmation.
- Audio changes never call native window APIs. Route display changes through `window_settings.gd`; editor-embedded windows remain editor-controlled. Preserve Screen Shake, Reduce Flashes and Damage Numbers settings and existing subtle feedback limits.
- Preserve clock domains: `time`/`run_delta` drive run schedules (Quick doubles the run clock); combat/status clocks and `statistics.combat_seconds` remain distinct. Keep each hook's declared clock; never apply a blanket second fast multiplier. Recalculate derived stats from baseline/snapshots, not repeatedly multiplied current values.
- Record successful real events only: damage excludes overkill, healing excludes overheal; base/evolved/fusion IDs remain separate and reactions are separately attributed. Keep bounded ten-second DPS storage and actual combat-duration denominators.

## Saves and compatibility

- Keep valid `user://savegame.json` data. Add defaults/migrations without dropping gold, meta ranks, unlocks, settings, discoveries, completed recipes, records, achievements or Starlight/nodes. Do not bump/reject the save version without a lossless migration; preserve corrupt-save backup behavior.
- Permanent bonuses are snapshots for the next run. Keep idempotent finish banking and atomic writes. New purchase/reward operations must handle save failure, restore in-memory balances/state and expose retry/error feedback; do not copy the legacy unchecked meta `buy()` path (see review). Reset must cover new persistent fields.
- Tests use isolated XDG paths/save filenames or `persistent=false`; never reset a player's real save. Never store credentials/tokens or generated `.godot/` caches in Git; preserve tracked `.gd.uid` files.

## Verification and publication

```sh
# Isolate save/config/cache state; never use the player's directories.
task_test_root="$(mktemp -d)"
export XDG_DATA_HOME="$task_test_root/data"
export XDG_CONFIG_HOME="$task_test_root/config"
export XDG_CACHE_HOME="$task_test_root/cache"
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh
# Gameplay, time, damage, content, pooling or performance changes:
GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh --long
# UI/window/input changes; requires an existing X11 display:
DISPLAY=:99 GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./tools/graphical_check.sh
# Repeat embedding checks with a real host window:
DISPLAY=:99 GODOT_BIN=/path/to/Godot_v4.7.2-stable_linux.x86_64 ./tools/graphical_check.sh --wid "${STERNENBRUCH_HOST_WINDOW_ID:?Set the real decimal X11 host ID}"
```

- Known test-isolation issue: an earlier randomized `choose(0)` can acquire Prism Disc before a later assertion expects it hidden (`tests/test_runner.gd`). See the architecture review before treating that failure as a gameplay regression; do not weaken the assertion.
- Cloud engine: `/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64`; system `godot` may be older. Both check scripts verify the version. Optional `STERNENBRUCH_LOG_DIR` isolates logs. See [smoke checks](docs/SMOKE_TEST.md) for targeted runners and Quick-mode simulation.
- Add meaningful coverage for changed contracts; preserve old checks. Intentional new content requires updated count expectations **and** functional coverage, not disabled tests. A zero engine exit code is insufficient: reject `SCRIPT ERROR`, `ERROR:`, `FAIL` and leaked-instance reports in logs. Inspect relevant graphical captures.
- Documentation-only changes: check paths/links, command accuracy and `git diff --check`; no gameplay refactor or new tests merely mirroring prose. Do not present previous stress/graphical results as newly executed. Simulations use explicit immunity/automatic choices and do not prove human balance, physical-controller behavior or GPU FPS.
- Update STATUS and affected documentation with scope, actual commands/results and remaining limits. Keep commits reviewable and follow the user's requested branch/publication scope. Before an authorized push, inspect/fetch remote changes, preserve history and never force-push or overwrite others' work. Verify the remote ref/tree after pushing; a local commit is not publication. Never claim an unverified upload or unrun test passed.
