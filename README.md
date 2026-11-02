# STERNENBRUCH

Eigenständiges, offline spielbares Cosmic-Fantasy-Survivor-Roguelite. Ausschließlich **Godot 4.7.2 Stable**, GDScript 2.0, Compatibility-Renderer. Keine Plugins, Asset-Downloads, .NET-Abhängigkeiten oder Netzwerkdienste erforderlich.

![Tatsächliche Arena mit automatischen Angriffen](docs/screenshots/arena.png)

## Starten

Godot **4.7.2 Stable** öffnen → Importieren → `project.godot` → F5. Alternativ:

```sh
godot --path .
```

In dieser Cloud-Umgebung ist die geprüfte Engine unter `/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64` installiert. Das systemweite `godot` ist **4.6.3** und wird für dieses Projekt nicht verwendet. Bei gesperrten Home-Verzeichnissen XDG_DATA_HOME, XDG_CONFIG_HOME und XDG_CACHE_HOME auf beschreibbare Verzeichnisse setzen; `tools/check.sh` erledigt das für Tests.

## Spielen

Hauptmenü → Neues Spiel → Held → Arena → Modus/Fluch → In den Riss → Runensegen. Bewegung mit WASD, Pfeiltasten oder linkem Controller-Stick. Waffen greifen automatisch an. XP-Juwelen einsammeln; pro Aufstieg genau eine von drei verschiedenen Verstärkungen wählen. Standardmäßig maximal sechs Waffen und sechs Passive. Bosse ab Minute 10 bringen evolutionsfähige Truhen: Basiswaffe Lv8 + Katalysator mindestens Lv1. Fusionen haben Vorrang. Überleben bis 30:00 gewinnt; Schnellmodus durchläuft dieselben Wellen in 15 realen Minuten.

- 1/2/3: Level-up-/Runenkarte auswählen.
- R: neu würfeln; T: überspringen; B: Verbannen aktivieren, danach eine Karte auswählen.
- Esc / Controller-Start: Pause; Enter/A bestätigt Menüs, Pfeile/D-Pad wechseln Fokus.
- Menüs, Reroll/Skip/Banish und alle Karten sind auch direkt mit Maus bzw. Controller-Fokus bedienbar.
- Truhen werden bei Berührung geöffnet; sie werden nicht magnetisch angezogen.
- Laternen können durch Angriffe zerstört werden und Heilung/Gold/Spezialpickups freigeben.

Gold wird beim Run-Ende einmalig verbucht. Shop-Upgrades wirken ab dem nächsten Run. Helden und die zweite Arena werden durch Erfolge freigeschaltet. Save: `user://savegame.json`; beschädigte Dateien werden nach `.corrupt.bak` gesichert.

## Inhalt

4 Helden, 12 Basiswaffen mit jeweils sieben Upgrades, 13 Passive, 12 Evolutionen, 2 Fusionen, 12 reguläre Gegner, 3 Bosse, 30 Wellen, 8 Runen, 2 Arenen. Normal/Schnell/Fluch, HP/XP/Gold, Status-Effekte, Truhen, Runen-/Level-up-Queue, Meta-Shop, Sammlung/Bestiarium und Einstellungen. Alle Grafiken und Klänge sind prozedural und original.

## Prüfen

```sh
GODOT_BIN=/pfad/zu/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh
# Zusätzlich drei Minuten Lastsimulation und vollständiger 30-Minuten-Run:
GODOT_BIN=/pfad/zu/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh --long
```

Einzelne Tests: `godot --headless --path . -s res://tests/test_runner.gd`, `tests/stress_runner.gd`, `tests/full_run_runner.gd`. Parsercheck: `godot --headless --editor --path . --quit`. `tools/check.sh` kontrolliert zusätzlich Logs auf Scriptfehler, Fehlerausgaben und Leaks, da Godot bei manchen Scriptfehlern keinen Fehlerstatus liefert. Tests schreiben keine echten Spielerfortschritte.

`tests/visual_runner.gd` benötigt einen tatsächlichen oder virtuellen Bildschirm, läuft **ohne** `--headless`, prüft Tastatur-/simulierte Stickbewegung und fotografiert zehn Menüs/Spielzustände sowie UI-Skalierung. Zielverzeichnis optional über `STERNENBRUCH_CAPTURE_DIR`, sonst `user://captures`. Ein physischer Controller und Audio-Wiedergabe müssen auf dem Zielrechner manuell geprüft werden.

## Debug-Werkzeuge

Nur `OS.is_debug_build()`, nur während einer laufenden Welt: F6 → 09:50, F7 → 10:00, F8 → 20:00, F9 → 29:00; F10 → +500 XP; F11 → Nadel/Bogen/Frost Lv8 mit Katalysatoren; F12 → echte evolutionsfähige Truhe +500 Run-Gold. In Release-Exports deaktiviert. Diese Werkzeuge nutzen dieselbe Inventar-, Truhen- und Kampfimplementierung wie das Spiel.

## Aufbau und Grenzen

`STATUS.md` enthält den Fortsetzungsstand und tatsächliche Testergebnisse. `DESIGN.md` erläutert Architektur und bewusste Vereinfachungen. `BALANCE.md` nennt die Datenquellen. `docs/SMOKE_TEST.md` trennt automatisiert geprüfte Bedienabläufe von offenen manuellen Prüfungen. Prüflogs liegen unter `test-results/`.

Die Inspiration sind automatische Angriffe, Minutenwellen, drei Upgrade-Angebote, 6+6 Ausrüstung und Truhenevolutionen. Namen, Welt, Zahlen, Rezepte, Formen und Klänge sind eigene Inhalte gemäß Spezifikation. Es werden keine Assets des Vorbilds verwendet.
