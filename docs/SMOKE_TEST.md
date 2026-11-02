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

Phase E1 adds legacy-save migration, bounded hit statistics, reversible instability-band state and fusion element-union tests. Phase E graphical acceptance remains pending E2–E6 implementation.

Phase E2: `tests/mutation_runner.gd` tests all 45 base/evolved effects, slot and chest rules, fusion imprint variants, Echo cadence, per-impact accounting, definition immutability and modal ordering. `tests/mutation_visual_runner.gd` captures selection at 1280×720, inherited evolution at 1600×900 and fusion imprints at 1920×1080. Full-run and stress fixtures now create mutations and evolutions through the real model APIs.

E3 automated: `tests/rift_runner.gd` covers all seven actual affixes, rewards, i-frames, timing, pooled reuse, each boss, caps, rift scheduling/proximity/expiry and paused FIFO decisions. `tests/rift_visual_runner.gd` renders the actual marker, modal and Phase II HUD at 1280×720/1600×900/1920×1080 (`docs/screenshots/rift-node.png`, `rift-decision.png`, `boss-phase-two.png`). Full-run fixture chooses two stabilizations/two overcharges through the real API and verifies elites, boss transitions and all thirty waves. Stress fixture includes three Phase II bosses and affixed elites at Critical instability.

Manual E3: verify F/Y proximity, readable 0.3-second blink destination, Volatile warning, Guardian dash escape, Queen slow recovery, Storm ring safe gap, controller focus and new-run difficulty on target hardware. CPU simulations do not prove human balance or rendered frame rate.

E4 automated: `tests/reaction_runner.gd` tests all four pairs both ways, primary/secondary damage and radii, 3.0/1.5-second edges, table priority, neutral/same-element/fusion tags, boss dampening, per-second cap, label cap, secondary recursion guard, crit/execute/armor-once accounting, death-proc suppression, DoT ownership, mutation integration, fire regeneration lock and pool reuse. `tests/reaction_visual_runner.gd` captures all four real effects plus the real result entry at 1280×720; screenshots inspected in `docs/screenshots/element-reactions.png` and `reaction-result.png`. The general pause legend does not expose hidden evolution names.
