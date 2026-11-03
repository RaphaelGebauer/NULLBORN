# UI text cleanup — 2026-11-03

Continued current GitHub main `e058ab8`, including its newer navigation, recipe and balance fixes. This pass changes English presentation only; gameplay resources, balance, stable IDs, save schema, reward transactions and focus behavior are preserved.

- Main Menu / Star Forge: use the same shop name; upgrades separate name/rank/price from the effect and identify bonuses as per rank.
- Characters / New Run / arena selection: remove obvious introduction sentences; retain hero stats, starting weapons, locked states, mode duration and curse values.
- Star Map: **the Veil → Veil**. Show name, cost, effect, one prerequisite and a concise ownership/funds reason. No “Requires: None” or duplicated unlock explanation. Purchase restrictions remain local; genuine storage errors retain rollback/retry.
- Pause: compact equipment rows (three slots per line), recipe counts, instability band/value, node schedule/lifetime and affix history. Discovered recipe ingredients/chest gate, mutation details and instability modifiers remain in **Build Details**. F/Y help stays contextual at a nearby rift; remove the technical interaction radius from menus.
- Build Details: shorter headings, status/duration text and bonus descriptions; remove repeated element explanations and extra blank lines between equipment entries. Keep all six slots per category, levels, inheritance, effects, stats and recipe discovery rules. Attack interval belongs with current stats; temporary effects can correctly show None.
- Results: retain all measured statistics and reward rules; shorten pending-save help. Damage attribution/DPS/overkill explanation moves to the **Damage by Source** tooltip (mouse enabled). Fixed retry/navigation actions remain reachable.
- Settings / rune / upgrade / rift choices: concise help and editor-window explanation; keep effects, costs, accessibility options and confirmations.
- Collection and chest/reset screens were reviewed; their discovery/effect and irreversible-reset information remains.

## Verification

Godot **4.7.2.stable.official.ed1daf0bf**, GDScript 2.0, Compatibility renderer. Every suite uses isolated XDG paths; no player save was touched.

```sh
task_text_test_root="$(mktemp -d)"
export XDG_DATA_HOME="$task_text_test_root/data"
export XDG_CONFIG_HOME="$task_text_test_root/config"
export XDG_CACHE_HOME="$task_text_test_root/cache"
export GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64
./tools/check.sh
DISPLAY=:99 ./tools/graphical_check.sh
# Separate isolated XDG paths for the embedded run:
DISPLAY=:99 ./tools/graphical_check.sh --wid 6291488
```

- **1,106 functional PASS / 0 FAIL**, seven Python generator tests and exact staged generator outputs. Independent seed 115: 179 unit checks pass.
- **101 native graphical assertions**, including 20 new text/state/layout checks; **9 embedded assertions**, using a real X11 host window.
- New UI text coverage checks all eighteen star descriptions for single requirements and retained cost/effect; exact wallet and unlocked messages; local purchase hints; relocated recipe/instability information; contextual rift input help. At 1280×720, 1600×900 and 1920×1080 it checks inspector text height, complete six-slot Pause bounds and fixed Build/Result actions.
- Existing graphical coverage includes actual mouse/Enter/joypad navigation, selection persistence, UI scale 1.2, settings return/pause behavior, storage recovery, hidden collection, mutation inheritance and victory/defeat scrolling.
- Inspected captures for Star Map, full Pause, Build and results, including 1280×720. Evidence: `docs/screenshots/text-*.png`; final logs: `test-results/text-*.log`.
- Logs have no engine/script errors, failed assertions or leaked instances. The software graphics driver emits the existing unsupported VSync warning.
- `git diff --check` passes. No changes relative to `e058ab8` in gameplay resources, Model, Combat, World, rift rules, player or window settings. No long gameplay simulation was rerun for this presentation-only pass. Physical controller hardware and target desktop/DPI checks remain manual.

Exact copy expectations were updated without removing assertions. The new text runner is included in both standard check scripts. Publication hash is reported after verifying GitHub main's ref and tree.
