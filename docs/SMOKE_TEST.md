# Smoke-test checklist

Automated with **Godot 4.7.2 Stable**:

- Read-only Characters, locked name-only entries, explicit completed-recipe discovery, reset confirmation/cancel and persisted reset: `tests/test_runner.gd`.
- Import, resource dependencies and real combat tests: `tools/check.sh`.
- Slot rules, offer uniqueness, meta-gated tools, XP overflow, statuses, runes, Lv5/Lv5 evolution/fusion and serialized paused modals: `tests/test_runner.gd`.
- New weapon damage, disc bounce, mine pull/slow, execution bonus, timed movement, regeneration and collection visibility: same suite.
- Actual 1280×720 / 1600×900 / 1920×1080 native window changes and audio isolation: graphical `tests/window_runner.gd`.
- True embedded-mode protection: same runner with native `--wid`.
- English menus, rotated player arrow, keyboard/stick input: graphical `tests/visual_runner.gd`.
- Load caps and complete run: `tests/stress_runner.gd` and `tests/full_run_runner.gd`.

Manual target-hardware checks still recommended:

- [ ] Physical gamepad, focus navigation, Start/A and unlocked selection tools.
- [ ] Audio loudness and device changes.
- [ ] Fullscreen/windowed switching with the desktop window manager, DPI scaling.
- [ ] Human balance playthrough with fresh progression and a later meta build.
- [ ] Release export: debug shortcuts disabled.

Embedded editor windows are deliberately controlled by the editor. Run standalone to test native window sizing.

Phase E1 adds legacy-save migration, bounded hit statistics, reversible instability-band state and fusion element-union tests. The later E2–E6 sections below record the completed graphical acceptance.

Phase E2: `tests/mutation_runner.gd` tests all 45 base/evolved effects, slot and chest rules, fusion imprint variants, Echo cadence, per-impact accounting, definition immutability and modal ordering. `tests/mutation_visual_runner.gd` captures selection at 1280×720, inherited evolution at 1600×900 and fusion imprints at 1920×1080. Full-run and stress fixtures now create mutations and evolutions through the real model APIs.

E3 automated: `tests/rift_runner.gd` covers all seven actual affixes, rewards, i-frames, timing, pooled reuse, each boss, caps, rift scheduling/proximity/expiry and paused FIFO decisions. `tests/rift_visual_runner.gd` renders the actual marker, modal and Phase II HUD at 1280×720/1600×900/1920×1080 (`docs/screenshots/rift-node.png`, `rift-decision.png`, `boss-phase-two.png`). Full-run fixture chooses two stabilizations/two overcharges through the real API and verifies elites, boss transitions and all thirty waves. Stress fixture includes three Phase II bosses and affixed elites at Critical instability.

Manual E3: verify F/Y proximity, readable 0.3-second blink destination, Volatile warning, Guardian dash escape, Queen slow recovery, Storm ring safe gap, controller focus and new-run difficulty on target hardware. CPU simulations do not prove human balance or rendered frame rate.

E4 automated: `tests/reaction_runner.gd` tests all four pairs both ways, primary/secondary damage and radii, 3.0/1.5-second edges, table priority, neutral/same-element/fusion tags, boss dampening, per-second cap, label cap, secondary recursion guard, crit/execute/armor-once accounting, death-proc suppression, DoT ownership, mutation integration, fire regeneration lock and pool reuse. `tests/reaction_visual_runner.gd` captures all four real effects plus the real result entry at 1280×720; screenshots inspected in `docs/screenshots/element-reactions.png` and `reaction-result.png`. The general pause legend does not expose hidden evolution names.

E5/E6 final automated coverage:

- `tests/constellation_runner.gd`: 90 checks of all eighteen real bonuses, costs/chains, persistence, failed-write rollback/retry, finish rewards, reset and focus/snapshot isolation.
- `tests/polish_runner.gd`: 40 checks of actual statistics/overkill/healing/XP/source rows, normal/Quick DPS, critical numbers, flash/shake settings and bounds, secondary retaliation attribution, real Build/Result state transitions, recipe privacy, event counts, victory/defeat, mid-run achievements and controller-accessible save retry.
- `tests/catalog_runner.gd`: 49 actual attacks/AI/pipeline checks covering all 15 base weapons, all 15 normal evolutions, both fusions, all 15 enemy types and both arenas.
- `tools/graphical_check.sh`: standalone native resize/audio regression, original fifteen menu/input states, mutation/rift/reaction captures, three-resolution Star Map and Build/Result, UI scale 1.2. `--wid <decimal-X11-host-id>` verifies true embedding, controller-action focus, audio/display protection and embedded Build/Result screens.
- `tests/full_run_runner.gd`: every step of thirty run minutes with all eighteen stars, six inherited mutation loadouts, real boss transitions/elites/rift choices/reactions, measured source reconciliation and once-only capped rewards. `STERNENBRUCH_QUICK_TEST=1` exercises the same schedule in 900 combat seconds.

Inspected screenshots: `star-map-1280.png`, `star-map-scaled.png`, `build-details-1280.png`, `build-paths-1280.png`, `run-result-1280.png`, `embedded-build.png`; corresponding 1600/1920 captures and embedded-result captures are retained. The scripted screenshot fixture is distinct from the full per-step simulation.

Remaining manual checks listed above are still open: physical devices, real desktop editor/window-manager/DPI behavior, audible balancing, actual GPU frame pacing, release exports and human thirty-minute difficulty. No such manual/hardware claim is inferred from automation. See FINAL_REPORT_PHASE_E.md.

The final five constellation cases explicitly cover fresh secondary bonuses, inherited target-factor normalization, no bonus leakage to normal enemies, reaction-chain recipients and pooled mutation pulses.

## Maintenance regression runners

`tools/check.sh` additionally runs the staging-only generator diff and seven Python safety cases, then `maintenance_runner.gd`: real open/rename failures, rollback/retry/reload, pending discovery, UI focus, no discarded finish rewards, pure-definition identity and Collection privacy. No player save is used. Repeat the unit fixture with `STERNENBRUCH_TEST_SEED=115` (also 1, 42, 72047) in fresh XDG directories.

`tools/graphical_check.sh` includes `maintenance_visual_runner.gd` (hidden/known Collection, purchase errors, paused retry and pending results at all three sizes) and `render_readonly_runner.gd` (real draw output with state/RNG/pool/cadence snapshots). Movement fixtures finish the final physics callback before measuring. The optional renderer oracle accepts `STERNENBRUCH_RENDER_REFERENCE` pointing to a separately recovered pre-extraction draw script outside the project; it is not required for the normal suite. Current acceptance evidence and limitations: [MAINTENANCE_REPORT.md](MAINTENANCE_REPORT.md).
