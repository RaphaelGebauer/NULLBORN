# Phase E delivery ledger

Specification: `NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md` (preserved verbatim).

## E1 — foundation implemented

- Additive version-1 save defaults for `starlight` and `constellation_nodes`, numeric/type/uniqueness validation, existing corruption handling and reset behavior preserved. No currency is awarded and no Star Map purchase UI exists yet.
- `scripts/run_statistics.gd` is connected to actual `world.hit`, healing and damage taken. Damage excludes overkill; base/evolved weapon IDs remain separate; crits require an actual critical hit. Eleven fixed second buckets calculate peak ten-second average DPS. Display/complete secondary-source attribution are E6 work.
- Explicit `run_delta` shares the wave clock's Quick Mode conversion and clamps to the remaining run duration.
- `scripts/data/element_tags.gd`: existing weapon tags and recursive sorted set-union for evolutions/fusions. No reactions are enabled until E4.
- `scripts/rift_instability.gd`: deterministic clamping, peak, reversible bands and copied band modifiers. Owned by each run, but intentionally not advanced or applied to gameplay until E3 supplies the complete director/node/UI integration.
- Run-local mutation map and constellation snapshot establish the existing model's integration points. They do not claim implemented mutation effects or talent bonuses.

## Remaining delivery

E2: all 45 mutation definitions/effects, mandatory level-4 modal inserted before pending level-ups, inherited imprints for all 15 evolutions and both 100%/50% fusions, bounded secondary hooks and tests.

E3: activate instability with HUD/director/gold integration, four proximity-only interactive rift nodes, seven elite affixes with bounded director and rewards, distinct HP boss phases and specified telegraphs.

E4: four bidirectional reactions, per-target timestamps/cooldown, proc protection, global event budget, boss dampening and attribution tests.

E5: 18 constellation nodes, persistent Starlight awards capped at eight, rollback-safe purchases, actual next-run bonuses and Star Map UI.

E6: subtle feedback, detailed statistics/result UI, spoiler-safe Build Details, graphical smoke captures, stress/full-run validation, documentation synchronization.

Do not describe E2–E6 as delivered. Do not change `resources/pacing.tres`, weapon IDs, 6+6 slots, Lv5/Lv5 evolution gates, historical chest eligibility or completed-recipe privacy.
