# Changelog

## Window, progression and English-content update

- Separated audio settings from display mutations; added Godot 4.7's explicit native embedding detection.
- 1920×1080 default standalone window, verified native resolution choices, disabled display controls with an explanation while embedded.
- Slower opening movement and five-minute enemy/spawn ramp.
- 16 meta upgrades including timed speed growth, regeneration, crit, area, duration and cooldown; selection tools require purchases.
- English game content, UI and current documentation; collection reveals equipment/heroes only after selection/acquisition.
- Three new weapons, four new passives and three matching evolutions, with functional combat tests.
- Evolutions/fusions require base weapons Lv5+ and matching passive Lv5 in a qualifying boss chest.
- Player arrow rotates with facing; removed its direction dot.

## Original four implementation phases

- A (`300e13c`): playable menu-to-result loop, automatic projectile, HP/XP, three-card upgrades and core tests.
- B (`fe564b7`): full original combat catalog, passive stats, enemy AI, statuses, spatial hash and pools.
- C (`de4196b`): thirty waves, bosses, chests, evolution/fusion, runes, arenas and serial modal flow.
- D (`6e9cfc1`): persistence, unlocks, meta shop, settings, procedural audio, controller support and validation.
