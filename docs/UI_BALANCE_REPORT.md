# UI, navigation and small balance corrections — 2026-11-03

Baseline: GitHub `main` / `7e37c94e204e37a08b3c56e6cf4c7eccd4754504`, verified remotely before editing. Existing project continued with Godot **4.7.2.stable.official.ed1daf0bf**, GDScript 2.0 and Compatibility rendering.

## Changes

- Star Map selection changes only through Button.pressed (mouse click, Enter or controller A). Its persistent three-pixel constellation-colored outline remains when pointer/focus moves; focus is a separate inset one-pixel ring. Purchased stars retain the selection and have a distinct symbol/color plus a disabled Owned button. Hover is a subtle background change.
- Read-only SaveManager.star_purchase_error reports owned, named prerequisite or exact required/available Starlight in that priority. Normal restrictions never write save.warning. The map owns its inspector text and recreates it on entry; real technical errors and earlier pending writes remain global. Atomic transactions, rollback, retry and save version/fields are unchanged. Star Map also exposes existing pending-progress retry controls.
- Pause/Build recipe summaries use RunModel.recipe_matches, shared with actual chest eligibility. All bases and the catalyst must be equipped; ready additionally requires recipe-defined Lv5 thresholds. Counts exclude consumed components/completed equipped results and count each Registry recipe once. Unknown recipes expose counts only; actual completed discoveries retain requirements. The 10:00 boss-spawn chest gate and fusion priority remain intact.
- Settings now has a distinct SETTINGS navigation state. Back/Esc/controller B returns to the originating Pause or main menu. Pause stays active until explicit Resume or Pause cancel. The graphical tests found that this engine's built-in UI actions had keyboard bindings only; setup_input now explicitly binds A/B, D-pad and the left stick for menu interaction.
- Central movement pacing: `0.75 × 0.95 = 0.7125`. Lyra/Eira **156.75 px/s**, Brann **146.0625**, Noctis **174.5625**, before unchanged additive bonuses and 500 px/s cap.
- Central raw outgoing damage: **0.93**, through RunModel.base_player_damage. Might includes it once, and fixed raw Chain Spark/Frost Thorns/Blood Thorns reflection/pickup Nova/death-fire/DoT sources use the same helper. Hit-derived mutations/reactions inherit the adjusted damage without another factor. Day/Night’s orbit-to-beam conversion marks its inherited global factor so the second parameterization preserves the existing Might bonus formula while excluding a second nerf; a high-Might regression verifies the actual beam. Existing rounding/minimum-one damage remains; individual small hits can therefore differ from exactly −7%. [Calculation details](../BALANCE.md#small-global-player-damage-adjustment-2026-11-03).

No weapon/enemy/hero catalog definitions, evolution thresholds, wave schedules, XP/loot/gold, incoming damage, HP/healing or Quick clock rules changed. All 153 generated resources and nine generated scripts still match staged generator output. Only the separate pacing resource changes numerical inputs.

## Executed verification

| Check | Result |
| --- | --- |
| Godot 4.7.2 import/parser | Passed |
| Existing functional suites plus targeted regressions | **1098 PASS / 0 FAIL**: 179 unit, 404 mutations, 103 rifts, 111 reactions, 91 constellations, 40 polish, 49 catalog, 33 maintenance, 56 balance, 32 UI fixes |
| Python generator safety + staging check | Seven tests passed; catalog/scripts exact |
| Independent unit seed 115 | 179 PASS; default 72047 covered by full suite |
| Native graphical checks at 1280×720, 1600×900, 1920×1080 and existing 1.2 UI-scale cases | **81 PASS**, including 36 new real mouse/key/joypad-event assertions |
| Actual X11 host embedding | **9 PASS**, including D-pad focus and A confirmation, no native resize requests |
| Full normal simulation | **30:00 / 1800 combat seconds**, victory, 26,379 kills, 23 elites, six boss phase transitions, 18,346 reactions; 51.861 s CPU wall time |
| Full Quick simulation | **30:00 / 900 combat seconds**, victory, 13,095 kills, 22 elites, six transitions, 9,279 reactions; 37.756 s |
| Stress | **180 simulated seconds / 5400 steps**, peaks 382 enemies / 261 projectiles / 300 pickups; 12,448 kills, 7,197 reactions; 36.578 s |

Commands: isolated XDG directories and `STERNENBRUCH_LOG_DIR`, `./tools/check.sh --long`, final `./tools/check.sh` including the exact Day/Night inherited-factor regression, `STERNENBRUCH_QUICK_TEST=1 … -s res://tests/full_run_runner.gd`, `DISPLAY=:99 ./tools/graphical_check.sh`, extended `ui_fixes_visual_runner.gd`, and `./tools/graphical_check.sh --wid 6291488` against an actual 1920×1080 X11 host. Additional seed: `STERNENBRUCH_TEST_SEED=115 … -s res://tests/test_runner.gd`.

Evidence: current `test-results/{unit,mutations,rifts,reactions,constellations,polish,catalog,maintenance,balance-fixes,ui-fixes,ui-fixes-visual,full-run,quick-run,stress,embedded,embedded-ui}.log` and `docs/screenshots/ui-fixes-{star,pause}-{1280,1600,1920}.png`. Relevant captures were inspected for clear persistent selection, owned/locked states, readable inspector and Pause navigation. Final logs have no Script Errors, engine ERROR lines, failures or leaked-instance reports. The known software-driver VSync warning remains.

Simulations use explicit immunity/automatic choices. Synthetic raw joypad events verify bindings and UI flow; they do not establish physical-controller behavior. Human difficulty/feel, target GPU performance, audio, desktop DPI and release exports remain manual checks.

## Reviewable commits and publication

- `50b3e4c`: explicit Star Map selection, precise local restrictions, persistence protection and regression coverage.
- `f93365a`: matching/ready equipment recipes, disclosure protection and shared chest query.
- `4f64766`: Settings return-to-pause navigation and live pause tests.
- `b46cd27`: central movement/damage factors, full-catalog regressions and balance documentation.
- `ef233f2`: verified real controller bindings and graphical regression runner.
- `419c583`: remaining raw player damage and Day/Night inherited-factor protection, with targeted tests.
- The commit containing this report adds final logs, captures and acceptance documentation. Its exact published GitHub hash is reported in the final response after remote ref/tree verification.
