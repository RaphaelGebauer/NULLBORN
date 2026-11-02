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
