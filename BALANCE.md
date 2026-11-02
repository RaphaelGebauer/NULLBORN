# Balance und Datenpflege

Verbindliche Startwerte stammen aus `CODEX_MASTERPROMPT.md`. Aktuelle ausführbare Daten:

| Inhalt | Quelle |
|---|---|
| 12 Waffen, Startwerte, sieben konkrete Level-Upgrades | `resources/weapons/*.tres` (`values`, `upgrades`) |
| 13 Passive mit additiven Stat-Boni | `resources/passives/*.tres` |
| 12 Gegner und 3 Bosse, HP/Speed/Kontakt/XP/Radius | `resources/enemies/*.tres` |
| 4 Helden und Startwaffen/Boni | `resources/characters/*.tres` |
| 30 gewichtete Wellen, Bosse, Runenereignisse | `resources/waves/*.tres` |
| 12 Evolutionen + 2 Fusionen, Komponenten und Angriffszusätze | `resources/evolutions/*.tres` |
| 8 Runen und Erklärungen | `resources/runes/*.tres`; Prozessoren in Model/World/Combat |
| Gewichtete Laternenbeute und Luck-Gewichtung | `resources/loot_table.tres` |
| Arenapaletten und Dichtefaktor | `resources/stages/*.tres` |
| Metapreise, Max-Ränge, Save-Defaults und Unlocks | `scripts/save_manager.gd`, `META`, `defaults()`, `unlocks()` |
| Stat-Neuberechnung, Caps, XP-Kurve und Belohnungen | `scripts/run_model.gd` |
| Gegner-/Minutenskalierung, Dropchancen, Statuszeiten, Poolcaps | `scripts/world.gd` |

Die Definitionen sind im Godot-Inspector editierbar. `tools/generate_data.py` erzeugt den gesamten Originalkatalog neu und **überschreibt** vorhandene Katalogdateien; deshalb entweder Generator oder `.tres` als Quelle einer Balanceänderung wählen und konsistent halten.

Start Lyra: HP 100, Tempo 220, Magnet 95, Might 1, Cooldown 1, Crit 5 % ×1,5; Heldbonus XP +10 %. Waffen Lv1–8, Passive Lv1–5, 6+6 Slots. Passive Boni werden addiert und dann genau einmal auf Basiswerte angewendet. Multiplicity gewährt auf Lv2/4 +1 Anzahl, sonst je +5 % Projektilschaden. Flächenradius max. Faktor 3, Tempo max. 500, zusätzliche Anzahl max. 6, Kritchance max. 60 %, Cooldown mindestens 0,12 s. Max-HP-Änderungen erhalten den aktuellen HP-Anteil.

XP-Bedarf: `round(8 + 9*(level-1) + .2*(level-1)^2)`. Rest-XP bleibt erhalten. Simulation pausiert für jede anstehende Wahl. Fallbacks: +25 Gold; +30 HP (voll → Gold); +10 % nächster XP-Bedarf. Skip: +20 % nächster Bedarf. Growth wird für solche Prozentbelohnungen nicht ein zweites Mal angewendet.

Minutenskalierung folgt den Formeln der Spezifikation: Spawnrate `1.6+.38*m+.008*m*m`; Cap `min(420,55+12*m)`; HP `(1+.055*m+.0025*m*m)*(1+.006*max(level-1,0))`; Kontakt `1+.035*m`; Speed `min(1.35,1+.012*m)`. Fünfminutensprünge geben Spawn- und HP-Faktoren `.09/.10` pro Tier. Fluch erhöht Menge/HP/Speed wie spezifiziert und beim Ergebnis das Gold. Sternenasche erhöht die Dichte um 10 %.

Zusätzliche, im Masterprompt nicht exakt bezifferte Waffenlevel geben +15 % Basisschaden. Orbit-Duration verändert den wirksamen Umlaufradius leicht; zusätzliche Anzahl erhöht bei Aura den Radius statt unsichtbare Geschosse zu erzeugen. Bossfreeze ist auf 0,4 s begrenzt, Slowwirkung halbiert. Die Mindestanker aller Waffenlevel sind im Generator sichtbar.
