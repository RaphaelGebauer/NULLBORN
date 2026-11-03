# Safe catalog generation

Use `python3 tools/check_generated.py` first. It copies both generators and their input brief into a fresh temporary tree, runs them there, and compares the complete output file set and bytes against the checkout. It also validates stable IDs/filenames against `tools/catalog_ids.json`. It never rewrites the checked project and has no apply/update mode. `tools/check.sh` runs it plus seven real drift/error/read-only tests before Godot.

| Generator | Overwritten by a direct manual invocation in the repository |
|---|---|
| `tools/generate_data.py` | `scripts/data/definition.gd` and eight `{weapon,passive,enemy,character,wave,evolution,rune,stage}_definition.gd` subclasses; `.tres` files in `resources/{weapons,passives,enemies,characters,waves,evolutions,runes,stages}/` |
| `tools/generate_mutations.py` | `.tres` files in `resources/mutations/`; expects that directory and reads weapon filenames plus mutation names/order from `NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md` |

Current output: 153 catalog resources and nine data scripts. Neither generator owns `resources/pacing.tres`, `resources/loot_table.tres`, constellation definitions, affix/reaction definition modules or gameplay scripts. Tracked Godot UIDs remain untouched by generation.

The mutation generator still has a positional 45-effect table and count assertions. This maintenance does not replace that source format: its coupling is now checked safely against the actual output. Do not edit the historical brief casually or regenerate directly to make a failing check disappear.

For a deliberately requested content change: keep stable existing IDs, update generator/source and affected resources together, review the diff, and update the ID baseline only when new/changed IDs are intentional. Extend Registry, unlock/save migration, element tags, mutation/evolution compatibility and functional tests as required. Run the staging check again. A matching generator is a reproducibility check, not proof of gameplay correctness.

`tests/test_generator_safety.py` works only on temporary copies and proves clean/no-write behavior, numeric drift, renamed IDs, missing/extra definitions, data-script drift and failed generation. The ID JSON is a review baseline, not a second runtime catalog.
