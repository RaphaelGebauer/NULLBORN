# CODEX-MASTERPROMPT — „STERNENBRUCH“
## Vollständiges, eigenständiges Vampire-Survivors-inspiriertes Roguelite in Godot 4.7.2

Du bist ein erfahrener **Godot-4.7.2-Entwickler, Gameplay-Programmierer, Technical Game Designer, UX-Designer, Performance-Engineer und QA-Engineer**. Arbeite **direkt in diesem Repository**. Dein Auftrag ist nicht, mir nur Code zu zeigen oder einen Plan zu schreiben, sondern ein **spielbares, startbares, möglichst vollständiges Godot-Projekt** zu erstellen, zu testen und sauber zu dokumentieren.

## 0. UNVERHANDELBARE REGELN

1. Verwende **ausschließlich Godot 4.7.2 Stable / Godot 4.x**, **GDScript 2.0**, Godot-4-Szenen, Godot-4-Signale und Godot-4-APIs. **Niemals Godot 3.x!** Insbesondere: `CharacterBody2D` statt `KinematicBody2D`; `@export` statt `export`; `@onready` statt `onready`; `instantiate()` statt `instance()`; `await` statt `yield`; Godot-4-`Tween` über `create_tween()`; bei Top-down-Bewegung `CharacterBody2D.velocity = direction * speed` und danach `move_and_slide()` **ohne delta-Argument**; `TileMapLayer` statt altem/deprecated `TileMap` verwenden, sofern überhaupt Tilemaps gebraucht werden.
2. Verwende nur tatsächlich vorhandene Funktionen und Properties der **Godot-4.7.2-Dokumentation**. Mische keine Tutorials aus Godot 3 oder inkompatiblen experimentellen Godot-4.8-Betas hinein. Wenn du nur eine andere Godot-4.x-Version lokal vorfindest, dokumentiere das und nutze nur dafür nachgewiesene kompatible APIs; keinesfalls stillschweigend Godot 3.
3. **Alle Inhalte original**: eigene Spielwelt, Charaktere, Texte, Namen, Symbole, Karten, Musik und Grafiken. Nicht die Namen, Originalsprites, Audio, UI oder geschützte Charaktere von Vampire Survivors kopieren. Verwende dessen *Spielprinzipien* als Inspiration, nicht dessen Markenassets.
4. **Kein Pseudocode, keine TODO-Stubs in Pflichtsystemen, keine bloße Demo mit nur einer Waffe.** Schreibe funktionierenden Code und echte `.tscn`/`.gd`/`.tres`/Konfigurationsdateien. Erstelle gültige `project.godot`, setze `run/main_scene` und alle Input-Actions. Ein frischer Import muss funktionieren.
5. **Arbeite iterativ in Phasen**, aber stoppe nicht nach einem Architekturentwurf. Nach jeder Phase: Godot-Import-/Parserprüfung, automatisierte Tests, Fehler beheben, dann weiter. Eine unfertige Featureliste darf nicht als „fertig“ behauptet werden. Falls die Ausführungsumgebung eine harte Grenze setzt, priorisiere eine **vollständig spielbare, fehlerfreie Kernschleife** vor kosmetischen Extras und dokumentiere exakt, was noch fehlt.
6. Keine kostenpflichtigen Assets, keine fragwürdigen Downloads und keine vorausgesetzten externen Plugins. Notwendige Platzhaltergrafiken müssen direkt aus Godot per `draw_*()`/Shapes/Gradienten/Shader oder aus selbst erzeugten Dateien bereitgestellt werden. Verweise nie auf fehlende Assets.
7. Halte das Spiel jederzeit bedienbar: Startbildschirm → Charakterwahl → Arena → Überleben/Leveln/Kämpfen → Sieg/Niederlage → Ergebnis → Neustart/Meta-Upgrades. Tastatur und Gamepad; Menüs mit Maus/Tastatur/Gamepad.
8. **Kommentiere schwierige Algorithmen**, nutze typisierte GDScript-Signaturen, `class_name` nur ohne Namenskollisionen, saubere Node-Pfade und Signals statt enger, zyklischer Kopplung. Datengetrieben statt 12 Waffen als gigantische `if/elif`-Kette zu programmieren.
9. Sämtliche Balancewerte sollen in zentralen Resources/Konfigurationsdaten editierbar sein; die Zahlen unten sind verbindliche **Start-Balance**, keine Behauptung, exakt die Originalwerte des Vorbilds zu sein.
10. **Kommunikation und Ingame-Texte auf Deutsch**, technische Variablen, Dateien und IDs auf Englisch. Keine Rückfragen nach Kleinigkeiten: triff selbst sinnvolle Entscheidungen und setze um.

## 1. PRODUKTVISION UND CORE LOOP

**Arbeitstitel:** STERNENBRUCH. Genre: 2D-Top-down-Arena-Survival / Bullet-Heaven / Roguelite. Stil: düstere, farbige Cosmic-Fantasy mit lesbaren Silhouetten und deutlich unterscheidbaren Projektilen.

- Steuerung des Helden über WASD/Pfeiltasten oder linken Stick; **alle Waffen greifen automatisch** an. Kein manuelles Zielen/Schießen im normalen Modus.
- Schwärme von Gegnern spawnen außerhalb des sichtbaren Bildes, verfolgen den Helden, verursachen bei Berührung Schaden.
- Kills erzeugen Erfahrungsjuwelen (XP), Gold und selten Spezialgegenstände; nahe XP werden automatisch eingesammelt, durch Magnetradius angezogen.
- Bei jedem Level-up **pausiert** die Simulation und es erscheinen standardmäßig **GENAU 3 unterschiedliche, legal auswählbare Angebote**: neue Waffe, Waffenlevel, neues Passivitem oder Passivlevel. Der Spieler wählt exakt eines. Reroll/Skip/Banish funktionieren zuverlässig.
- Maximal **6 Waffen-Slots + 6 Passiv-Slots**, die Startwaffe belegt einen Waffenslot. **Waffen Level 1–8**, **Passives Level 1–5**. Zusätzliche Level-ups nach vollen/maximierten Slots gewähren Heilen/Gold und optional später Limit-Break.
- Synergien: Maximale Basiswaffe + bestimmtes Passivitem + geeignete Boss-Truhe → **mächtige Waffen-Evolution**. Einige spezielle Zweiwaffen-**Fusionen** verbrauchen zwei Basiswaffen und belegen danach nur einen Slot.
- Jede volle Spielminute startet eine neue Gegnerwelle; alle **5 Minuten** eine spürbare Schwierigkeitsspitze mit Elite/Boss; um Minute **10/20/25** stärkere Schwärme; endgültiger Überlebenssieg bei **30:00** oder Tod vorher.
- Gold fließt **runübergreifend** in permanente Upgrades und Freischaltungen. Verschiedene Helden, Waffen, Relikte/Runensegen, Gegnerbestienbuch und zwei Arenen schaffen Wiederspielwert.

## 2. TECHNISCHE PROJEKTANFORDERUNGEN

**Ziel:** Godot 4.7.2 Stable, GDScript 2.0, Windows/Linux Desktop, ohne .NET, Vulkan Compatibility/GL Compatibility-Renderer für breite Unterstützung falls sinnvoll; mindestens eine frei skalierbare 16:9-Darstellung (Referenz 1280×720), saubere Responsive-UI und korrektes Maus-/Gamepad-Fokusverhalten. 60 Physik-Ticks/s, delta-unabhängige Bewegung. Spielzeit von Pause/Level-up entkoppeln.

Vorgeschlagene Struktur (falls besser, begründet modifizieren):

```
project.godot
README.md
DESIGN.md
BALANCE.md
CHANGELOG.md
STATUS.md   # Fortschritt und offene Punkte über Codex-Sessions hinweg
scenes/
  main_menu.tscn
  character_select.tscn
  stage_select.tscn
  game.tscn
  player.tscn
  enemy.tscn
  projectile.tscn
  pickup.tscn
  chest.tscn
  hud.tscn
  level_up_menu.tscn
  pause_menu.tscn
  result_screen.tscn
  meta_shop.tscn
  collection_screen.tscn
  settings_screen.tscn
scripts/
  autoload/game_state.gd
  autoload/save_manager.gd
  autoload/audio_manager.gd
  core/run_controller.gd
  core/run_clock.gd
  core/enemy_director.gd
  core/wave_data.gd
  core/loot_director.gd
  core/spatial_hash.gd
  core/combat_system.gd
  core/damage_numbers.gd
  entities/player.gd
  entities/enemy.gd
  entities/boss.gd
  entities/projectile.gd
  entities/pickup.gd
  entities/chest.gd
  equipment/inventory.gd
  equipment/weapon_controller.gd
  equipment/weapon_behaviors.gd
  equipment/evolution_system.gd
  equipment/stats_calculator.gd
  ui/level_up_menu.gd
  ui/hud.gd
  ui/menus/*.gd
  data/weapon_definition.gd
  data/passive_definition.gd
  data/enemy_definition.gd
  data/character_definition.gd
  data/wave_definition.gd
  data/evolution_recipe.gd
  data/rune_definition.gd
  data/registry.gd
resources/weapons/*.tres
resources/passives/*.tres
resources/enemies/*.tres
resources/characters/*.tres
resources/waves/*.tres
resources/evolutions/*.tres
resources/runes/*.tres
resources/stages/*.tres
tests/test_runner.gd
tests/test_*.gd
tools/  (nur bei Bedarf für originale Sounds/Grafiken)
```

Erstelle **typed custom `Resource`-Klassen** für Waffen, passive Effekte, Gegner, Charaktere, Wellen, Evolutionen und Runen. Beachte Import-/Load-Reihenfolgen und Zyklen. Registry lädt Ressourcen nur einmal und validiert **einzigartige IDs, positive Werte, gültige Abhängigkeiten**. Runtime-Inventory speichert eigene mutable Level/State, statt globale `.tres`-Definitionen zu verändern. Signals für XP, Health, Level, Inventory, Kills, Boss, Runen, Zeit, Gold, Endzustand.

Spieler: `CharacterBody2D` mit top-down floating movement und `MOTION_MODE_FLOATING`, Collider, Hurtbox, Pickupradius, `Camera2D` mit Glättung. Leichte Gegner können effizienter mit Node2D + rechnerischem Bewegungssystem / Pooling und manuellem Broadphase bewegt werden; vermeide tausende komplexe `CharacterBody2D`-Physikabfragen. Projektile/Kontakte: klar definierte Hitbox-/Hurtbox-Logik bzw. manuelle Kreis-/Segmenttreffer unter Verwendung eines Spatial Hash. Keine „auf gut Glück“ pro Frame über alle Projektile × alle Gegner iterieren. Nutze `Area2D` wo sinnvoll, lege Collision-Layers/Masks explizit fest; falls du eigene Kollision implementierst, dokumentiere die Entscheidung. Für viele ähnliche Sprites kann `MultiMeshInstance2D` eingesetzt werden, wenn die Godot-4.7.2-API korrekt ist.

Kameratechnisch spawnt der EnemyDirector in einem rechteckigen **Ring mindestens 60–160 Weltpixel außerhalb des sichtbaren Kamerabereichs**, nicht einfach an festen Weltkoordinaten. Kein Spawn im sicheren Nahbereich des Spielers. Normale Gegner weit außerhalb dürfen mit Distanzhysterese despawnen, Bosse nicht (Boss ggf. an den Bildschirmrand repositionieren). Offline-Spiel; keinerlei Netzwerk nötig.

## 3. HELDEN, HP UND BASISWERTE

Spieler-Grundwerte (vor Held-/Meta-/Passiv-Modifikatoren):
- HP: **100/100**; Bewegungsgeschwindigkeit **220 px/s**; Rüstung **0**; Regeneration **0 HP/s**; Magnetradius **95 px**.
- Macht/Might **100 %**; Cooldownrate **100 %** des Basis-Cooldowns; Flächenradius **100 %**; Projektilgeschwindigkeit **100 %**; Wirkungsdauer **100 %**; zusätzliche Projektile **0**; XP-Growth **100 %**; Gold-Greed **100 %**; Luck **100 %**; Crit-Chance **5 %**, Crit-Faktor **1,5**.
- Bei Feindkontakt Schaden `max(1, round(enemy_contact_damage - effective_armor))`; **0,65 s Unverwundbarkeit** nach Treffer, blinkende Figur, leichtes Screen-Shake und Rückstoß; Ausnahme: eine Trefferquelle darf nicht durch mehrere Collisions innerhalb eines Frames mehrfach zuschlagen.
- Heilung darf niemals `max_hp` überschreiten; Änderung von `max_hp` erhält vorzugsweise prozentualen aktuellen HP-Anteil oder dokumentiert feste Regel; nie Tod durch fehlerhaftes Rechnen beim Ausrüsten.
- Angriffs-/Schadensformel: `damage = max(1, round(base_damage * (1 + might_bonus) * source_multiplier * crit_multiplier))`; pro Treffer/DoT gelten definierte Hit-Intervalle je Target. Multiplikatoren und additive Boni strikt getrennt; Caps: Cooldown **mindestens 0,12 s**, Movement **höchstens 500 px/s**, Crit **maximal 60 %**, Flächen-Bonus sinnvoll deckeln, Amount-Bonus maximal **+6**.
- Status: `burn` (z. B. 4 Schaden/s für 3 s), `slow` (0,65× Speed, 2 s), `freeze` (0 Speed, 1,5 s; Boss nur abgeschwächt), `poison` (3 Schaden/s für 4 s), `knockback` (mit Resistenz). Verwende eine saubere StatusEffect-Verwaltung ohne unendliches Aufstapeln und ohne Referenzen auf tote Objekte.

**Vier eigenständige Charaktere**:

| Held | Startwaffe | HP | Speed | Bonus | Freischaltung |
|---|---|---:|---:|---|---|
| Lyra, Sternenläuferin | Arkannadel | 100 | 220 | +10 % XP | sofort |
| Brann, Aschenwächter | Aschebogen | 125 | 205 | +1 Rüstung; −5 % Cooldown | insgesamt 1.000 Kills |
| Noctis, Mondjäger | Mondklinge | 85 | 245 | +15 % Crit-Schaden; +10 % Luck | 10 Minuten überlebt |
| Eira, Frostseherin | Frostsplitter | 95 | 220 | +15 % Area; +10 % Projektilspeed | 1 Boss besiegt |

Hero-Auswahl zeigt Werte, Startwaffe, Freischaltstatus und animierte Vorschau; zu Spielbeginn mindestens Lyra wählbar. Persistente Unlocks im Save.

## 4. XP, LEVEL-UP, LOOT UND AUSWAHL AUS 3

- Gegner werfen XP-Drops entsprechend Definition: kleine Gegner 1–3 XP, mittlere 3–6, Elite 12–24, Boss 60–100. Verwende unterschiedliche Juwelenfarben und gegebenenfalls aggregierten Wert, **kein XP-Verlust** durch Pooling/Culling.
- `xp_to_next(level) = round(8 + 9*(level-1) + 0.2*(level-1)^2)` als **nur für dieses Spiel definierte Startkurve**; Level startet bei 1, XP beginnt bei 0. Growth auf erhaltene XP anwenden, Rest-XP übertragen. Beim gleichzeitigen Sammeln großer Mengen nacheinander **mehrere Level-up-Auswahlen in einer Warteschlange**, nie überschreiben und nie ungefragt automatisch auswählen.
- Auswahl-Generator: erst alle legalen Optionen sammeln; besessene noch nicht maximale Items als Upgrade; nicht besessene Items nur, wenn zugehöriger 6er-Slot frei, Item freigeschaltet und nicht gebannt; Evolutionswaffen nie direkt als gewöhnliche Level-up-Option; keine doppelten Optionen in derselben Auswahl. Wähle **3** per gewichteter Zufallsziehung **ohne Zurücklegen**; Raritäten/Weights liegen in Ressourcen (häufig 100, ungewöhnlich 60, selten 25). Wenn weniger als 3 legale Einträge verbleiben, ergänze eindeutig definierte Hilfsoptionen (`+25 Gold`, `+30 HP wenn verletzt, sonst +25 Gold`, `+10 % XP zum nächsten Level`); niemals drei identische Schaltflächen. Nach Auswahl korrekt weiterschalten und Pause nur lösen, wenn alle Level-up-Events verarbeitet sind.
- Reroll: zu Beginn jedes Runs **2 Verwendungen**, neue drei Optionen nach den Regeln, keine doppelten, aktuelle Auswahl verwerfen. Skip: **1 Verwendung**, Auswahl überspringen und **+20 %** des nächsten XP-Bedarfs hinzufügen (dadurch evtl. weitere Level-ups in Queue). Banish: **1 Verwendung**, der Spieler markiert eine der drei Karten; diese Basiswaffe/dieses Passivitem erscheint für den Rest des Runs nie wieder als neue Option (bereits erworbene Items dürfen dadurch nicht kaputtgehen); sofort drei neue legale Optionen zeigen. Optionale Meta-Upgrades erhöhen diese Kontingente. Controls sowohl per Schaltfläche als auch per Hotkey und Gamepad.
- Beim Level-up pausiert die Welt **vollständig**: Bewegung, EnemyDirector, Run-Timer, Projektile, DoT, Animationen in der Spielwelt; das UI läuft über passende `process_mode` weiter. Upgrade-Auswahl erhöht das Level nur einmal, UI aktualisiert, gewährt **0,3 s Unverwundbarkeit** nach Fortsetzung.
- Gold geht **nicht** nach dem Run verloren. Gegner droppen Gold selten (normale Gegner ca. 3 % Chance auf 1–3 Gold, Elites ca. 20 % auf 5–10, Bosse garantierte 20–50). Goldwert von Greed beeinflusst; separater persistent gespeicherter Wallet.
- Pickups: XP-Juwel, Goldmünze, Heilnahrung **+30 HP**, Magnetstern sammelt alle auf dem Boden liegenden XP, Stoppuhr friert normale Gegner für **5 s** ein, Sternenexplosion verursacht an Bildschirmgegnern **100 Schaden** (Bosse nur 25 %), Schatztruhe, selten `+10 % Luck bis Run-Ende`. Die drei Spezialpickups dürfen aus zerstörbaren Weltobjekten/„Leuchtsteinen“ fallen. Loot-Gewichte konfigurieren.
- Magneteffekt: XP bei <= Magnetradius mit sanfter Beschleunigung zum Spieler ziehen; bei Bildschirmwechsel behalten oder verlustfrei aggregieren. Cap **250 sichtbare XP-Objekte**; bei Überschreitung Werte in größeren Juwelen zusammenfassen.

## 5. ZWÖLF ECHTE WAFFEN, LEVEL 1–8

Implementiere **jede** Waffe tatsächlich mit unterscheidbarem Angriff, Zielwahl, Timern, Schaden, VFX und 7 Upgrades bis Level 8. Baseline bei Charakter-Stats = 100 %. Level-up-Upgrades pro Waffe sind in Daten definiert; **nicht bloß Textkarten, die nichts tun**.

| ID / angezeigter Name | Verhalten auf Lv 1 | Startwerte (Basis) | Identität / Upgrades |
|---|---|---|---|
| `arcane_needle` – Arkannadel | Schuss auf nächsten Feind | 13 Schaden, 0,85 s CD, 450 px/s, 1 Projektil | Zielsuche, Durchschlag ab Lv4; Lv2/3/5/7 mehr Damage, Lv6 +1 Projektil, Lv8 +2 Durchschläge |
| `ash_bow` – Aschebogen | 3 Geschosse als Fächer in Bewegungs-/letzte Blickrichtung | 8 Schaden je Pfeil, 1,35 s CD, 330 px/s | Lv2 +Damage; Lv3 +2 Pfeile; Lv4 Burn; Lv5/7 Damage; Lv6 größerer Winkel; Lv8 +2 Pfeile |
| `spark_orbit` – Funkenkranz | kreisende Kugeln treffen Gegner mit Hit-CD | 9 Schaden, 2 Orbs, Radius 70, je Target 0,65 s | Lv3 +1 Orb, Lv4 Rotation schneller, Lv6 +1 Orb, Lv8 +15 Radius; Orbit skaliert mit Duration/Area |
| `thorn_halo` – Dornenring | permanente Schadensaura um Figur | 5 Schaden pro 0,75 s, Radius 65 | Lv2/4/6 +Schaden, Lv3/5 +Radius, Lv7 Slow, Lv8 −0,15 s Tick |
| `lightning_call` – Blitzruf | Einschlag bei zufälligem sichtbarem Feind | 22 Schaden, 2,6 s CD, Radius 45 | Warnmarker 0,25 s; Lv3 +1 Strike, Lv5 chain to 2nd target, Lv8 +2 Strikes |
| `moon_blade` – Mondklinge | Sichel wird auf Feind geworfen, kehrt zurück | 17 Schaden, 1,6 s CD, 340 px/s | Ein und derselbe Gegner max. alle 0,4 s; Lv4 +1 Sichel, Lv6 Pierce, Lv8 +1 Sichel |
| `frost_shard` – Frostsplitter | schneller Linien-Schuss | 12 Schaden, 1,0 s CD, 520 px/s | 30 % Chance auf 1,5 s Slow; Lv3 +1 Projektil, Lv5 Pierce, Lv8 Split nach Treffer |
| `storm_bomb` – Sturmbombe | ballistische Bombe explodiert nach 0,8 s am Zielpunkt | 27 Schaden, 3,1 s CD, Radius 75 | Vorhersage/Telegraph; Lv3 +Radius, Lv5 Burn, Lv7 −CD, Lv8 zweiter kleiner Nachschlag |
| `shadow_fan` – Schattenfächer | Salve in **8 Richtungen** um Spieler | 9 Schaden, 2,0 s CD, 360 px/s | Lv3 12 Richtungen, Lv5 Poison, Lv8 zweite versetzte Salve |
| `sun_beam` – Sonnenlaser | 1 rotierender Strahl, Segment-Hit | 7 Schaden pro 0,25 s, 2,5 s CD, 1,1 s Dauer, Länge 220 | Gegner entlang Ray/Segment; Lv3 +Dauer, Lv5 +Länge, Lv8 zweiter Strahl |
| `soul_well` – Seelensog | auf 1 Gegner zentrierte stationäre Schadenszone | 6 Schaden pro 0,5 s, Radius 80, 3 s Dauer, 5 s CD | Lv3 +Dauer, Lv5 leichter Sog, Lv7 +Radius, Lv8 zweite Zone |
| `meteor_rain` – Splitterregen | mehrere kleine Einschläge rund um Zielcluster | 14 Schaden, 2,8 s CD, 3 Meteore, Radius 38 | Lv3 +2 Meteore, Lv5 Burn, Lv7 +Area, Lv8 +3 Meteore |

Definiere **auf Lv2 bis Lv8** bei jeder Waffe eine vollständige Änderungsliste (Tabellenwerte oben sind Mindest-Anker; ergänze die hier nicht genannten Level mit +10–20 % Waffenschaden oder −5–8 % Cooldown). Alle Werte in WeaponDefinition/LevelUpgrade-Daten, nicht an UI gekoppelt. Anzeige: nächstes Level erklärt die **konkrete Änderung**. Zielwahl deterministisch: nächster gültiger Feind, dann ID als Tie-Breaker; randomisierte Ziele per run-seeded RNG. Für Auren, Laser, Orbits und Meteore eigene Verhalten-Komponenten, nicht bloß umgefärbte Standardkugeln. Damage-Over-Time, Krits, Effekte, Durchschlag, Treffer-Entprellung und Despawn sauber implementieren. Leerlaufwaffen dürfen keine Gegner-Nodes ins Leere dereferenzieren.

## 6. PASSIVITEMS, LEVEL 1–5 UND ECHTE STAT-SYNERGIEN

Passivitems wirken sofort und werden **nach jeder Änderung aus Basis + Held + Meta + allen Passiven + Runen** deterministisch neu berechnet (keine fehlerhaften, dauernd aufeinander multiplizierten Buffs). Werte je Level; absolute Boni vs. Prozentboni explizit behandeln:

| ID / Name | Bonus **pro Level** | bei Level 5 |
|---|---|---|
| `power_core` – Kraftstein | +10 % Waffenschaden/Might | +50 % |
| `clockwork` – Uhrwerk | −7 % Waffen-CD | −35 % |
| `runner_boots` – Laufstiefel | +8 % Bewegungstempo | +40 % |
| `focus_lens` – Linsenfokus | +10 % Flächenradius | +50 % |
| `multiplicity` – Mehrfachkern | +1 Projektilanzahl **nur auf Level 2 und 4**; andere Levels +5 % Projektilschaden | +2 Amount, +15 % Projectile-Damage |
| `lasting_seal` – Dauersiegel | +12 % Effektdauer | +60 % |
| `magnet_ring` – Magnetring | +25 px Magnetradius | +125 px |
| `blood_vial` – Blutphiole | +15 % Max-HP | +75 % |
| `iron_skin` – Eisenhaut | +1 Rüstung | +5 |
| `growth_crown` – Wachstumskrone | +10 % XP-Ausbeute | +50 % |
| `lucky_die` – Glückswürfel | +10 % Luck; wirkt auf Crit/seltene Drops | +50 % |
| `wind_feather` – Windfeder | +10 % Projektilgeschwindigkeit | +50 % |
| `greed_amulet` – Goldamulett | +12 % Gold-Ertrag | +60 % |

**13 Passivitems**, maximal sechs pro Run; alle können aus dem Pool rollen. Zwingend korrekte Integration in Waffencooldowns, Schaden, Größe, Dauer, Anzahl, XP, Magnet, Dropchance, Rüstung, HP. Bei Amount pro Waffentyp sinnvoll interpretieren: mehr Orbitkugeln / zusätzliche Lightning-Strikes / weitere Meteore; Auren bekommen stattdessen +Radius oder −Tickintervall, damit keine unsichtbaren Bonusschüsse entstehen. UI zeigt exakt effektive Werte.

## 7. ZWÖLF EVOLUTIONEN + ZWEI FUSIONEN

Basisregeln, angelehnt an den Genreklassiker: **Basiswaffe Level 8** und **passendes Passivitem mindestens Level 1**; dann **geeignete Truhe eines Bosses, der ab Spielminute 10:00 gespawnt ist**. Ein nach 10:00 geöffnetes Chest eines vorher gespawnten Bosses bleibt nicht evolutionsfähig. Zuerst berechtigte **Fusionen**, dann berechtigte normale Evolutionen prüfen, mit deterministischer Reihenfolge oder auswählbarer Auswahl bei mehreren Rezepten. Je normaler Truhe **höchstens eine** Evolution/Fusion. Passivitem wird **nicht verbraucht**; die Basiswaffe wird vollständig entfernt und die Evo erhält genau einen Waffenslot (Fusionen aus 2 Waffen → 1 Slot frei). Keine doppelten Evo-Instanzen, keine Doppel-Buffs aus alten Waffenskripten, laufende Projektile der Basis dürfen kontrolliert auslaufen oder konsistent entfernt werden. Evolved Weapons kommen auf Evolutionslevel 1, sind direkt stark, haben kein normales 1–8-Leveling.

**Verbindliche Rezeptliste:**

| Basiswaffe + Katalysator | Evolution | Eigenständiger Zusatz-Effekt |
|---|---|---|
| Arkannadel + Kraftstein | **Sternenstich** | 3 sehr schnelle Nadeln; durchdringen 5 Gegner; markieren getroffene Feinde für +15 % Folgeschaden |
| Aschebogen + Laufstiefel | **Phönixfächer** | 7 brennende Pfeile pro Salve; verbrannte Gegner lösen beim Tod kleine Feuerwellen aus |
| Funkenkranz + Dauersiegel | **Sonnenorbit** | 6 rotierende Orbs + periodische radiale Lichtimpulse |
| Dornenring + Eisenhaut | **Blutstachelkreis** | größerer Aura-Ring, Rückschaden und maximal 1 HP Heilung pro 15 getroffene Gegner |
| Blitzruf + Glückswürfel | **Donnergitter** | 4 Kettenblitze; jeder springt bis zu 4 Ziele an |
| Mondklinge + Linsenfokus | **Sichelmondsturm** | 3 große zurückkehrende Sicheln mit Spiralbahn |
| Frostsplitter + Windfeder | **Eisprisma** | Schuss zerplatzt in 4 Splitter, verlangsamt zuverlässig, selten 0,5 s Frost |
| Sturmbombe + Wachstumskrone | **Meteorherz** | großer Einschlag + 5 kleine Sekundärexplosionen |
| Schattenfächer + Mehrfachkern | **Nachtgewitter** | 16er-Rundumsalve + versetzte giftige Nachsalve |
| Sonnenlaser + Uhrwerk | **Zenithstrahl** | zwei gegenläufig rotierende Strahlen mit stärkerer Dauer |
| Seelensog + Blutphiole | **Geisterbrunnen** | 2 starke Sogzonen; max. 1 HP Heilung je 20 Zone-Kills |
| Splitterregen + Magnetring | **Kometenschauer** | Meteorwolke, zieht kleine Gegner minimal ins Zentrum; 10 Einschläge |

**Fusionen** (zusätzliche optionale Rezepte, haben Vorrang, wenn beide Basen noch existieren):
- Aschebogen **Lv8** + Frostsplitter **Lv8** + Laufstiefel → **Dämmersturm**, ein kombinierter eisig-brennender 360°-Fächer; beide Basiswaffen werden entfernt, ein Slot frei.
- Mondklinge **Lv8** + Sonnenlaser **Lv8** + Linsenfokus → **Tag-und-Nacht**, zwei orbitierende Energieklingen samt periodischem Durchmesser-Strahl; beide werden entfernt, ein Slot frei.

Das System darf nicht „Evolution“ nur visuell anzeigen: Angriffsmuster, Damage, Status, Slots und Rezeptprüfung müssen funktional sein. Inventar und Sammlung zeigen „Rezept entdeckt“, sobald beide Komponenten erstmals gemeinsam besessen wurden, aber die tatsächliche Evolution muss wie beschrieben durch Chest erfolgen. In der Pause kann man Waffe + benötigtes Passiv nachschlagen.

## 8. GEGNER, KAMPFKI UND BOSSE

**Mindestens 12 reguläre Gegnertypen** mit Daten und unterscheidbaren Silhouetten sowie **3 Bosstypen**. Basiswerte gelten bei Minute 0 vor Skalierung, `xp` und `gold` wie angegeben:

| ID / Name | HP | Speed px/s | Kontakt | XP | Verhalten |
|---|---:|---:|---:|---:|---|
| `wisp` Flackergeist | 14 | 85 | 6 | 1 | langsamer Verfolger, sehr häufig |
| `mite` Sternenmilbe | 8 | 150 | 4 | 1 | Schwarm, kleine Kollisionsradien |
| `crawler` Schlundkriecher | 24 | 105 | 8 | 2 | einfacher Verfolger |
| `guardian` Nebelwächter | 70 | 60 | 12 | 4 | tanky, knockbackresistent |
| `charger` Splitterläufer | 35 | 95 | 10 | 3 | warnt 0,7 s, stürmt 0,6 s mit 280 px/s |
| `sniper` Schattenrufer | 40 | 75 | 7 | 4 | hält Abstand und schießt alle 3,5 s eine langsame Kugel |
| `zigzag` Kristallflieger | 28 | 145 | 8 | 3 | seitliches Pendeln |
| `splitter` Bruchling | 48 | 90 | 9 | 4 | teilt sich bei Tod in 2 kleine Milben, begrenzte Rekursion |
| `shield` Eisenhüter | 110 | 65 | 14 | 6 | 35 % Schadenreduktion frontal, Flanke normal |
| `healer` Dunstpriester | 50 | 70 | 7 | 5 | heilt nahe Feinde +4 HP/s, max. 4 Ziele, erkennbar |
| `bomber` Leerenbombe | 36 | 110 | 12 | 4 | Explosion bei Tod, 0,8 s sichtbare Warnzone |
| `elite_hunter` Elitejäger | 180 | 115 | 16 | 14 | schneller verfolgend, CC-Resistenz |

Bosstypen mit eigener Animation/Telegraph, HP-Leiste, mindestens zwei unterscheidbaren Angriffen:
- **Astralwächter:** Basis-HP 850, Speed 65, Kontakt 18, 60 XP; radialer Projektillauf + langsamer Charge; spawnt Minute 5, 15, 25 mit höheren Skalen.
- **Leerenkönigin:** Basis-HP 1.250, Speed 75, Kontakt 20, 80 XP; beschwört kleine Adds + Gefahrenzonen; spawnt Minute 10 und 20.
- **Sturmkern:** Basis-HP 2.400, Speed 80, Kontakt 24, 100 XP; 3 Phasen bei 100/65/30 % HP, Strahlen und periodische Ringwelle; spawnt Minute 29. Wird bei 30:00 ggf. automatisch despawnt und gewährt nur dann Bonusgold, wenn vorher besiegt.

**Kein Spawn-Kill:** Boss-Ankunft mit Warnhinweis/rotem Marker, minimale Distanz zum Spieler, keine unlesbaren One-Shots. Normale Gegner verfolgen Spieler mit lokaler Separationslogik und minimalem Overlap; keine teure Navigation für offene Arena. Elite/Boss droppen immer eine Chest und Bonusgold; alle Unique-Kills korrekt zählen. Gegner können Burn/Slow/Freeze/Knockback unterschiedlich widerstehen; Bosse haben mindestens 50 % Slow-Reduktion, Freeze maximal 0,4 s. Gegnerprojektile von Spielerprojektilen unterscheiden; Player-Hurtbox funktioniert. Stationäre Spezialangriffe zeigen Telegraphen bevor Schaden entsteht.

## 9. EXAKTE 30-MINUTEN-WELLENSTRUKTUR UND SCHWIERIGKEIT

**Eine neue WaveDefinition pro voller Minute 0 bis 29**; Spawns laufen innerhalb jeder Minute kontinuierlich. Verwende die folgende Liste als Inhaltsplan; mache gewichtete Zusammensetzung in `.tres` editierbar. Bei 30:00, wenn Spieler lebt: Sieg, RunClock stoppt.

| Minute | Zusammensetzung / Event |
|---|---|
| 00 | Flackergeister 80 %, Milben 20 %, Einstieg |
| 01 | Geister 55 %, Milben 30 %, Kriecher 15 % |
| 02 | Milben 50 %, Kriecher 35 %, Geister 15 %; erste Minischwarmspitze |
| 03 | Wächter 20 %, Kriecher 50 %, Milben 30 % |
| 04 | Kriecher 50 %, Splitterläufer 20 %, Geister 30 %; Charge-Telegraph lernen |
| 05 | Astralwächter-Boss, dazu Kriecher/Wächter; Elitebonus |
| 06 | Kristallflieger 35 %, Milben 35 %, Kriecher 30 % |
| 07 | Schattenrufer 15 %, Kristallflieger 35 %, Kriecher 50 % |
| 08 | Bruchlinge 20 %, Kristallflieger 40 %, Splitterläufer 40 % |
| 09 | Elitejäger 8 %, Wächter 30 %, Flieger 62 % |
| 10 | Leerenkönigin-Boss; ab jetzt evolutionsfähige Bosstruhen |
| 11 | Milben 45 %, Schattenrufer 20 %, Bruchlinge 35 %; Runensegen-Event |
| 12 | Eisenhüter 15 %, Splitterläufer 35 %, Kriecher 50 % |
| 13 | Dunstpriester 12 %, Eisenhüter 23 %, Flieger 65 % |
| 14 | Leerenbomben 25 %, Flieger 40 %, Wächter 35 % |
| 15 | Astralwächter-Boss + dichte Elitejäger-Schar |
| 16 | Bruchlinge 30 %, Milben 40 %, Dunstpriester 30 % |
| 17 | Schattenrufer 30 %, Leerenbomben 30 %, Eisenhüter 40 % |
| 18 | Splitterläufer 45 %, Flieger 30 %, Elitejäger 25 % |
| 19 | Eisenhüter 35 %, Dunstpriester 20 %, Elitejäger 45 % |
| 20 | Leerenkönigin-Boss mit verstärkten Beschwörungen |
| 21 | Bruchlinge 35 %, Schattenrufer 30 %, Leerenbomben 35 %; Runensegen-Event |
| 22 | Elitejäger 35 %, Flieger 45 %, Wächter 20 % |
| 23 | Dunstpriester 15 %, Eisenhüter 35 %, Leerenbomben 50 % |
| 24 | Milben 45 %, Elitejäger 30 %, Flieger 25 %; kurzer Riesenschwarm |
| 25 | Astralwächter-Boss; dauerhaft höhere Dichte |
| 26 | Eisenhüter 35 %, Schattenrufer 25 %, Elitejäger 40 % |
| 27 | Leerenbomben 40 %, Flieger 30 %, Splitterläufer 30 % |
| 28 | Dunstpriester 20 %, Eisenhüter 30 %, Elitejäger 50 % |
| 29 | **Sturmkern-Endboss**; Elitejäger/Wächter/Flieger, Endspurt |
| 30 | **Sieg** bei überlebendem Spieler; kein weiterer Wave-Spawn |

**Dynamische Skalierung, bei Spawn fest berechnet**:

```
m = floor(run_time_seconds / 60)            # 0 ... 29
base_spawn_per_sec = 1.6 + 0.38*m + 0.008*m*m
spawn_rate = base_spawn_per_sec
normal_enemy_cap = min(420, 55 + 12*m)
hp_scale = (1.0 + 0.055*m + 0.0025*m*m) * (1.0 + 0.006*max(player_level-1,0))
damage_scale = 1.0 + 0.035*m
speed_scale = min(1.35, 1.0 + 0.012*m)
# Alle 5 Minuten, ab Minute 5: pro Schwierigkeitssprung zusätzlich
spike_tier = floor(m / 5)
spawn_rate *= 1.0 + 0.09*spike_tier
hp_scale *= 1.0 + 0.10*spike_tier
# Curse ist vom Spieler wählbar und skaliert Menge, HP, Speed
spawn_rate *= 1.0 + curse_bonus
hp_scale *= 1.0 + curse_bonus
speed_scale *= 1.0 + 0.35*curse_bonus
```

Durch die Scaling-Formeln darf kein Boss dauerhaft unverwundbar werden. Spawn über `delta`-basiertes **Token-Bucket/Budget** gegen Framerate-Abhängigkeit, Weighted WaveTable und Cap. Wenn Cap erreicht, Spawnbudget begrenzen, nicht später 500 Feinde in einem Frame nachspawnen. Special-Events und Bosse umgehen normalen Cap mit eigenem eng begrenzten Budget. Die Wellen werden beim Minutenwechsel einmalig gewechselt, kein Doppelauslösen durch Timerungenauigkeit. Visualisiere Wave-Beginn (z. B. „Welle 15 – Aschesturm“) und Warnungen 10 s vor Bossen.

**Modi:** Normal 30 Minuten; **Schnellmodus** als optionaler zweiter Modus mit 15 realen Minuten, indem Wellen-/Ereigniszeit um Faktor 2 voranschreitet, aber alle Lauf-/Schadensmechaniken normal schnell bleiben. Für Debug gibt es getrennt dokumentierte Development-Shortcuts; nicht standardmäßig in Release aktiv. **Fluch/Curse** als optionaler, nachvollziehbarer +10–50-%-Difficulty-Schieberegler, der oben definierte Multiplikatoren beeinflusst und +10–50 % Goldbonus auf Endergebnis gewährt.

## 10. SCHATZTRUHEN UND RUNENSEGEN

**Truhen:** Bei jedem Boss garantierter Drop, von Elitejägern 8 % Chance; Truhen bleiben in der Welt bis aufgesammelt, werden nicht automatisch vom Magnet eingesaugt. Beim Öffnen pausiert die Welt; kurze, überspringbare Truhenanimation. Vor Minute 10 erhalten nicht evolutionsfähige Truhen +Gold und eine zufällige **legale Upgrade-Stufe eines bereits besessenen, nicht maximalen Items**; wenn nichts aufrüstbar, 100 Gold. Evolutionsfähige Truhen prüfen zuerst Fusion/Evolution, gewähren diese und zusätzlich 60–140 Gold, ansonsten normales Upgrade/Gold. Luck kann sehr selten eine Bonus-Upgrade-Karte gewähren (Deckel max. 3 Rewards). Nicht mit dem aktuellen Level-up-UI konkurrieren: Queue-/State-Machine für Chest, LevelUp, RuneSelection.

**Runensegen als separates Run-Modifier-System**: Am Anfang eines Runs (vor Bewegung) und bei **11:00 und 21:00** wählt der Spieler jeweils **1 aus 3 verschiedenen Runen**, insgesamt max. 3. Runen belegen **keine** Waffen- oder Passivslots, sind mit Reroll nicht identisch. Mindestens 8 original benannte, tatsächlich funktionierende Runen:

1. **Splitterstern**: Projektile von Nadel/Frostsplitter bekommen +1 Projektil; keine Aura beeinflussen.
2. **Kampfresonanz**: alle 20 Kills −15 % Waffen-Cooldown für 3 s (nicht beliebig stackbar).
3. **Blutmond**: alle 30 Kills +3 HP, max. 30 HP/min.
4. **Eiskrone**: 8 % Chance auf Slow bei jedem direkten Treffer, Bosse reduziert.
5. **Schatzsucher**: +25 % Gold und +1 Reroll sofort.
6. **Kettenfunke**: 5 % Chance je direktem Treffer auf kleinen Blitz zu zweitem Feind (interner Cooldown 0,25 s).
7. **Schildzeichen**: 10 % Chance, Kontakt-Schaden zu blockieren; sichtbares VFX.
8. **Zeitanker**: +25 % Wirkdauer von Orbit, Zone und Laser.

Runen sind für Buildvielfalt wichtig, aber ihre Prozessoren dürfen bei Hunderten Treffern/s keine ungebremsten rekursiven Procs starten (z. B. Proc-Tag verhindert Procs aus Procs).

## 11. SPIELWELTEN, PICKUP-OBJEKTE UND SICHTBARKEIT

- **Zwei komplett spielbare Arenen**: „Nebelheide“ (Start, dunkles Gras, Bäume, Ruinen, leuchtende Pilze) und „Sternenasche“ (Freischaltung nach erstem Sieg, Krater und kristalline Bodenmuster). Beide praktisch endlose offene Flächen um den Player (Chunk-/Pattern-Recycling oder wiederholte Tiles mit korrektem Mapping); keine harte unsichtbare Mauer. Hindernisse nur sparsam, damit Massen nicht hängenbleiben. Stage-spezifische Farbpalette, Wave-Multiplier und Bühnen-Dekor.
- **TileMapLayer** falls Tiles genutzt werden, nicht Godot-3-TileMap. Erzeuge eigene, funktionierende TileSet-Ressourcen oder zeichne prozedurale Pattern mit seed-basierter Platzierung. Immer lesbarer Untergrund.
- Zerstörbare „Sternenlaternen“ außerhalb des Nahbereichs alle 20–35 s max. 8 im aktiven Spielraum; können Heilung/Gold/Magnet/Stoppuhr freigeben. Keine „Level ist leer“-Optik.
- Entitäten: erkennbare Körperform, Schatten, klare Hit-/Hurt-Farben, HP-Bars für Bosse, kurze Damage-Flashs, einfache Partikel und Hitstop nur dosiert. Farbblindfreundliche Formen zusätzlich zu Farben, reduzierte Blink-/Screen-Shake-Optionen.

## 12. UI/UX – SPIELFERTIG, NICHT ENTWICKLERDEBUG

Erstelle ein konsistentes dunkles UI mit kontrastreichen, deutlich klickbaren Elementen, guten Margins, Skalierung und Keyboard-/Controller-Fokus. **Alle Texte auf Deutsch.** Szenen:
- **Hauptmenü**: Neues Spiel, Charaktere, Sammlung/Bestiarium, Meta-Upgrades, Einstellungen, Beenden; Spielname, minimalistischer Hintergrund.
- **Charakterauswahl**: 4 Figuren, Stats/Startwaffe, gesperrt/frei, Auswahl per Controller.
- **Arenawahl**: 2 Stages, Normal/Schnell, Curse, ggf. Rekord.
- **Ingame-HUD**: HP-Balken + Zahl, XP-Bar + LV, Spielzeit mm:ss, Killzähler, Run-Gold, aktuelle Welle, 6 Waffenicons mit Lv, 6 Passiveicons mit Lv, 3 Runeicons, Bossleben, deutliche Statusanzeigen. HUD darf Spieler in Bildschirmmitte nicht verdecken.
- **Level-Up-Popup**: wirklich **drei** große Karten mit Name/Icon/Level/Art/konkretem Effekt/Nächster-Stufe; Reroll, Skip, Banish mit verbleibenden Charges, Tastatur-Shortcuts 1/2/3, Fokus/hover, Verhindern von Doppelauswahl.
- **Evolutions-Truhe**: kurze Animation, Name/Farbe, Rezept und Hinweis „Neue Evolution!“; normales Upgrade unterscheidbar.
- **Pause (Esc/Start)**: Weiter, aktueller Build + beschreibbare Rezepte, Optionen, Run beenden (Bestätigung); laufende Spielwelt steht still.
- **Run-Ende**: Sieg/Niederlage, Überlebenszeit, Level, Kills, erhaltene Goldmenge, gewählte 6+6 Items, Evolutionen, Bosse, neu freigeschaltete Inhalte, „Erneut versuchen“ und „Zum Menü“. Gold **nur einmal** verbuchen.
- **Meta-Shop**: Preis, Wirkung, Level/maxLevel, Kauf/Unbezahlbar/Max, Wert sofort im nächsten Run, permanente Save-Daten.
- **Sammlung**: Waffen, Passives, Evolutionen, Runen, Gegner-Bestiarium, Unbekanntes als `???`, Fortschritt sowie Combos.
- **Einstellungen**: Master/Musik/SFX, Vollbild/Fenster, Auflösung sinnvoll, Screenshake an/aus, Flash-Reduktion, Schadenstexte an/aus, Controller-Deadzone, Skalierung der UI. Speichern/Neuladen.

## 13. META-PROGRESSION, UNLOCKS UND SAVE

`user://savegame.json` mit `version`, `total_gold`, `unlocked_characters`, `unlocked_stages`, `unlocked_weapons`, `unlocked_runes`, `meta_powerups`, `achievements`, `best_run_records`, `stats`, `settings`. Sichere Standardwerte und robuste Parser-/Versionsprüfung; beschädigte Datei: Backup/Fehlermeldung und neuer Save ohne Crash. Save nach Run, Shopkauf, Unlock und Settings-Änderung; niemals bei jedem Frame. Optional atomare Temp-Datei.

**Meta-Upgrades mit steigendem Preis**, jeweils maximal 5 Level außer wo markiert:
- Maximale HP +5 %/Rank, Kosten `50 * (rank+1)^2`.
- Schaden +3 %/Rank, Kosten `75 * (rank+1)^2`.
- Lauftempo +2 %/Rank, Kosten `50 * (rank+1)^2`.
- Magnetradius +10 px/Rank, Kosten `50 * (rank+1)^2`.
- XP +4 %/Rank, Kosten `75 * (rank+1)^2`.
- Gold +5 %/Rank, Kosten `75 * (rank+1)^2`.
- Rüstung +1 je 2 Ranks, Kosten `100 * (rank+1)^2`.
- Rerolls +1/Rank (max. 3 Ranks), Kosten `125 * (rank+1)^2`.
- Skip +1/Rank (max. 2), Kosten `100 * (rank+1)^2`.
- Banish +1/Rank (max. 2), Kosten `150 * (rank+1)^2`.

Achievements/Unlocks mindestens: erste 100 Kills, 1.000 Gesamtkills, 5/10/20/30 Minuten überlebt, erster Boss, erste Evo, erste Fusion, 10 verschiedene Passives gesehen, erstes Spiel gewonnen, 10.000 Gold gesammelt. An Events statt per-frame prüfen. Unlock-Items werden im Run-Angebotspool berücksichtigt und haben sichere Default-Sets, sodass das Spiel vom ersten Run an Spaß macht. Kein Shopkauf ohne ausreichendes Gold, keine negativen Wallets.

## 14. LEISTUNG, SPEICHER, KORREKTHEIT

**Ziel**: 60 FPS auf durchschnittlichem Desktop bei ca. **300–400 Gegnern**, 200+ aktiven Projektilen und großen XP-Mengen, soweit Hardware es erlaubt. Dokumentiere Messhardware/-verfahren, behaupte keine gemessenen FPS ohne Messung. Keine 30-minütige Speicherzunahme durch verlorene Nodes/Signale. Nutze Objektpools für Gegner/Projektile/XP; cappe Partikel und schalte Offscreen-VFX aus; werte Treffer über Spatial Hash (Zellgröße z. B. 96 px) oder geeignete Broadphase aus. Gruppensuche `get_nodes_in_group("enemies")` nicht für jeden Projektiltreffer in jedem Frame. Auf `is_instance_valid` und Node-Lebenszyklen achten. Keine Runtime-Resource-Mutationen, keine unendlich wachsenden Arrays und keine verwaisten Timer.

- Gegner-Normalkap 420, Projektile 650, Pickup-Objekte 300 (XP-Gruppierung erhält Gesamt-XP), FX-Pool nach Bedarf. Bosse/Sonderereignisse bewusst separat behandeln.
- Ein Gegner darf **genau einmal** sterben, XP und Gold und Kills nur einmal droppen; nach Reuse wird Zustand komplett zurückgesetzt (HP, Timers, Status, Material, Kollision).
- Unverwundbarkeit und Dot-Ticks nutzen Game-Time oder pausierende Nodes, keine `Time.get_ticks_msec()`-Zeitquelle, die trotz Pause weiterläuft.
- Alle UI-Modals werden von einer Zustandsmaschine koordiniert, damit Loot-Chest und LevelUp/RuneSelection sich nicht überlappen. `RUNNING`, `LEVELUP`, `CHEST`, `RUNE`, `PAUSED`, `VICTORY`, `DEFEAT`; nur gültige Übergänge.
- Strukturierte Debug-Logs nur in Dev-Build; keine Error-Spam-Flut. Sauberes Signal-Deconnect, wenn Pool-Objekte wiederverwendet werden.

## 15. TESTS UND ABNAHME — ZWINGEND DURCHFÜHREN

Implementiere automatisierte Tests **ohne zusätzliches Testframework**, z. B. `tests/test_runner.gd` als `SceneTree`-Skript; CLI `godot --headless --path . -s res://tests/test_runner.gd`. Tests geben `PASS`/`FAIL` aus und beenden mit Nichtnull-Exitcode bei Fehler. Falls `godot` nicht im PATH liegt, suche lokale Godot-4-Binärdatei und dokumentiere fehlende Ausführbarkeit ausdrücklich. Zusätzlich Godot-Import-/Parsercheck `godot --headless --editor --path . --quit` (bei Bedarf mit zur Version passender Option).

Tests mindestens:
1. Projekt kann importiert werden, alle Pflichtszenen und Resources laden; keine Parserfehler/fehlenden Dateireferenzen.
2. 4 Helden, 12 Basiswaffen, 12 Evolutionen, 2 Fusionen, 13 Passives, 12 reguläre Gegnertypen, 3 Bosstypen, 30 WaveDefinitions, 8 Runen und 2 Arenen sind korrekt registriert.
3. Jeder Gegenstand hat einzigartige IDs, gültige Levels, Werte, Beschreibungen und Ressourcenziele; jede Evolution zeigt auf existierende Komponenten.
4. Held startet mit exakt einer Waffe, 100 HP beim Standardhelden, korrekt skalierten Basisstats.
5. Schaden, Rüstung, I-Frames, Regeneration, Heilen und HP-Deckel funktionieren, Tod triggert genau einmal.
6. XP-Formel, Overflow, mehrfacher Level-up aus einem großen XP-Pickup, Level-up-Queue funktionieren.
7. Dreierauswahl ist **eindeutig**, weighted, schließt gesperrte/maximale/gebannte Items und volle Slots aus; Reroll/Skip/Banish zieht korrekte Charges ab.
8. Eine Waffe erreicht Level 8 und wird nicht mehr als Upgrade angeboten; Passive erreicht Level 5; maximum 6+6.
9. Evo scheitert ohne Passiv und vor evolutionsfähigem Boss; Evo gelingt mit Level 8 + Passiv Lv1 + passender Truhe; Slots korrekt; Fusion verbraucht beide Basiswaffen.
10. RunTime/Waves schreiten im Minutentakt voran; Wave 5/10/29 spawnt korrekten Boss; bei Pause bleibt die gesamte Simulation incl. Cooldowns stehen.
11. Schaden durch mindestens ein echtes Projektil, Aura, Orbit, Beam und Bombenexplosion funktioniert und trifft nicht unendlich oft pro Frame.
12. XP-Pickup-Pooling/Gem-Merging erhält Gesamtwert; Gold wird nicht mehrfach gesammelt.
13. Sieg bei 30:00, Niederlage bei 0 HP, keine doppelten Ergebnis-/Geldbuchungen.
14. Save/Load mit Standardwerten, Shop-Kauf, Unlocks, Einstellungen und korruptem Save (abfangen) funktioniert.
15. 3 parallele Modal-Events (z. B. XP-LevelUp + Truhe + Runensegen) erzeugen **keinen UI-Deadlock**.
16. Simulation mit Test-Welle und vielen Gegnern läuft mehrere Minuten ohne Exceptions; danach werden Entitäten/Signale korrekt abgebaut.

**Manuelle Smoke-Test-Checkliste** dokumentieren: Hauptmenü öffnen; erstes Spiel starten; WASD und Controller; Schaden nehmen; XP sammeln; drei Karten sehen; Levelup wählen; Reroll; 6+6 füllen; Boss bei 5; Evolution nach 10; Runes bei 11; Pause/Resume; Shop/Save; mehrere Runs; Fullscreen/Windowed; finaler Sieg. Biete einen **nur im Debugmodus** verfügbaren Testpfad, um Zeit auf 09:50, 10:00, 20:00 oder 29:00 zu setzen, XP/Gold/Equipment bereitzustellen und Evolutionen schnell zu testen; diese Shortcuts sind in Release deaktiviert. Testpfad verwendet dieselbe Logik, kein hardcodierter Fake-Erfolg.

## 16. ARBEITSREIHENFOLGE

Führe diese Phasen nacheinander selbstständig aus; nach jeder Phase tatsächliche Dateien erzeugen und testen:

**Phase A — lauffähiger Kern:** Godot-Projekt, Startmenü, eine Arena, Spielerbewegung/Kamera, zwei Gegnertypen, eine echte automatisch schießende Waffe, Kill/XP/LevelUp-Popup mit drei Karten, HP/Schaden, Timer, Gameover, Score. Schon jetzt startbar.

**Phase B — komplette Kampfbasis:** 12 reguläre Gegner, alle 12 Basiswaffen mit Level 1–8, 13 Passives, Slotgrenzen, XP/Gold/Heal, Reroll/Skip/Banish, zentrale Stats, Status-Effekte und Spatial Hash/Pooling. Tests reparieren.

**Phase C — volle Run-Struktur:** 30 minütliche Waves, 3 Bosse, Chests, 12 Evolutionen, 2 Fusionen, 8 Runensegen, zweite Arena, Sieg bei 30, Pause/Menu/Collection. Tests reparieren.

**Phase D — Meta und Polishing:** 4 Helden, Unlocks, Bestiarium, Meta-Shop, dauerhafte Saves, Einstellungen, weitere Sounds/VFX/UI-Animationen, Controller, Performance-Checks, vollständige Dokumentation. Tests reparieren.

Währenddessen sinnvolle kleine Commits verwenden, sofern bereits ein Git-Repository existiert. Nicht mit einer Dokumentation-only-Antwort abbrechen. **Führe STATUS.md nach jeder Phase mit erledigten Features, fehlenden Features, Testausgaben und nächstem konkretem Schritt fort**, damit die Arbeit in weiteren Codex-Sessions exakt fortgesetzt werden kann. **Die konkrete Umsetzung im Repository hat oberste Priorität.** Wenn bei einem Feature komplexe Effekte nicht performant umsetzbar sind, wähle eine einfachere echte Implementation mit gleichem spürbarem Verhalten und dokumentiere nur diese bewusste Abweichung.

## 17. FINALE LIEFERUNG / ANTWORTFORMAT

Am Ende soll dieses Verzeichnis ein vollständig öffnungsfähiges Godot-4.7.2-Projekt enthalten. Gib in deiner finalen Textantwort kompakt an:

1. Was ist tatsächlich implementiert (mit Stückzahlen und Featurestatus), was fehlt ggf. noch ausdrücklich?
2. Startanleitung: `Godot 4.7.2 -> Import -> project.godot -> F5` bzw. korrekte Main-Scene starten; optional CLI.
3. Ausgeführte Import-/Unit-/Smoke-Tests, konkrete Ergebnisse, eventuelle noch offene Bugs.
4. Schlüsseldateien/Ordner und wo Balance, Wellen, Waffen, Evolutionen und Freischaltungen editiert werden.
5. Welche für das Originalspiel typischen Mechaniken als Inspiration umgesetzt wurden und welche **bewusst eigene Designs/Startwerte** sind.

**Abnahmekriterium:** Ich kann das fertige Repository sofort mit **Godot 4.x (Ziel 4.7.2)** öffnen und spielen, ohne fehlende Dateien nachzuladen oder Godot-3-Code zu reparieren. Ich bekomme 30 Minuten ansteigende Gegnerwellen, Charakter-/Buildwahl, maximal 6 Waffen und 6 Passives, echte Level-ups aus **3 verschiedenen Angeboten**, Bosskämpfe und Evolutionsrezepte, automatisch kämpfende Waffen, XP, HP, UI, Gameover/Sieg und persistente Fortschritte. Die Pflichtfeatures müssen eine echte Implementierung besitzen und dürfen keine Attrappen sein.

**BEGINNE JETZT MIT DER UMSETZUNG IM REPOSITORY.**

## 18. FACHLICHE REFERENZEN ZUM PRÜFEN DER IMPLEMENTIERUNG

Nutze bei Unklarheiten **die aktuelle Godot-4-Dokumentation**, nicht Godot-3-Code. Offizielle technische Referenzen:
- Godot-4-Dokumentation: https://docs.godotengine.org/en/stable/
- `CharacterBody2D`: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
- `Area2D`: https://docs.godotengine.org/en/stable/classes/class_area2d.html
- Pause/Process-Modi: https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html
- `TileMapLayer`: https://docs.godotengine.org/en/stable/classes/class_tilemaplayer.html
- Performance-Ansätze: https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html

Bei Designfragen sind folgende **Mechanikbeschreibungen des Vorbilds**, nicht dessen Assets, hilfreiche Referenz: https://vampire.survivors.wiki/w/Level_up , https://vampire.survivors.wiki/w/Evolution , https://vampire.survivors.wiki/w/Enemies , https://vampire.survivors.wiki/w/Weapons , https://vampire.survivors.wiki/w/Passive_items . Typische Inspiration: pro Minute wechselnde Gegnerwellen; bis zu sechs Basiswaffen und sechs Passivitems; aus mehreren zufälligen Level-up-Angeboten wählen; voll gelevelte Waffe + passender Katalysator + geeignete Truhe für Evolution. **Die oben definierten 30-Minuten-Wellen, 12 Waffen, 13 Passives, 12 Evolutionen und konkreten Werte sind dagegen unsere eigene Spiel- und Startbalance**.
