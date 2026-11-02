# Phase E delivery ledger

Specification: `NULLBORN_CODEX_ERWEITERUNG_PHASE_E.md` (preserved verbatim).

## E1 — foundation implemented

- Additive version-1 save defaults for `starlight` and `constellation_nodes`, numeric/type/uniqueness validation, existing corruption handling and reset behavior preserved. No currency is awarded and no Star Map purchase UI exists yet.
- `scripts/run_statistics.gd` is connected to actual `world.hit`, healing and damage taken. Damage excludes overkill; base/evolved weapon IDs remain separate; crits require an actual critical hit. Eleven fixed second buckets calculate peak ten-second average DPS. Display/complete secondary-source attribution are E6 work.
- Explicit `run_delta` shares the wave clock's Quick Mode conversion and clamps to the remaining run duration.
- `scripts/data/element_tags.gd`: existing weapon tags and recursive sorted set-union for evolutions/fusions. No reactions are enabled until E4.
- `scripts/rift_instability.gd`: deterministic clamping, peak, reversible bands and copied band modifiers. Owned by each run, but intentionally not advanced or applied to gameplay until E3 supplies the complete director/node/UI integration.
- Run-local mutation map and constellation snapshot establish the existing model's integration points. They do not claim implemented mutation effects or talent bonuses.

## E2 — implemented

All 45 definitions and processors; mandatory paused Lv4 choice; normal/evolved effect tests for all 45; inheritance for all 15 normal evolutions and both primary/echo fusions. Shared proc budget, deterministic echo cadence, genuine projectiles/mines/secondary damage, timed zones, hit/cast/expiry counters, real contact retaliation and healing cap. No extra slots, no changed evolution gates and no recipe spoilers. English pause/build imprint display and three-resolution graphical captures. Existing full-run and stress fixtures now exercise real mutated/evolved loadouts.

## E3 — implemented

 active five-band instability/HUD/director/gold, four proximity-only paused risk/reward nodes, all seven bounded elite affixes, separate half-HP boss phases with real dashes, starfalls, curved bolts, capped summons/null zones and safe-gap rings/beams. See BALANCE.md and tests/rift_runner.gd.

## E4 — implemented

 four bidirectional reactions with final-hit attribution, cached base/evolution/fusion tags and successful mutation/status tags, fixed priority, per-target 3-second history/1.5-second cooldown, forty-events-per-combat-second budget, capped feedback, boss dampening, bounded chain/AoE, result damage entry and general pause legend. Real Burn/Poison ownership and no proc reentry; exhaustive functional, graphical, stress and full-run verification.

## Remaining delivery

E5: 18 constellation nodes, persistent Starlight awards capped at eight, rollback-safe purchases, actual next-run bonuses and Star Map UI.

E6: subtle feedback, detailed statistics/result UI, spoiler-safe Build Details, graphical smoke captures, stress/full-run validation, documentation synchronization.

E1–E4 are delivered; E5–E6 remain pending. Do not change `resources/pacing.tres`, weapon IDs, 6+6 slots, Lv5/Lv5 evolution gates, historical chest eligibility or completed-recipe privacy.
