# STERNENBRUCH – Fortschritt

Ziel: ausschließlich Godot 4.7.2 Stable, GDScript 2.0. Spezifikation: CODEX_MASTERPROMPT.md.

## Phase A
Implementiert: Projekt, Menü, CharacterBody2D + Kamera, offene Arena, zwei Gegner, Auto-Projektil, HP, XP/Overflow, drei Upgrade-Karten, Pause, Ergebnis/Neustart.
Validierung läuft; weitere Phasen noch offen.

Nächster Schritt: Phase-A-Import und automatisierte Tests mit verifiziertem Godot 4.7.2, danach Kampfbasis B.

Phase A validiert mit Godot 4.7.2.stable.official.ed1daf0bf: 7/7 automatisierte Prüfungen bestanden (Startstats, XP-Kurve, Overflow/Queue, drei Karten, Heal-Cap, echter Projektil-Kill, Tod/Ergebnis). Parserfehler behoben. Fokus-Callback gegen inzwischen entfernte Controls abgesichert. Editor-Socketwarnungen entstehen durch Sandbox-Netzwerksperre.

## Phase B abgeschlossen
12 Basiswaffen mit sieben datengetriebenen Upgrades, 13 Passives, 12 reguläre Gegner mit KI, 6+6 Slots, gewichtete Auswahl, Reroll/Skip/Banish, Slow/Freeze/Burn/Poison, manuelle Segment-/Kreistreffer mit Spatial Hash, wiederverwendete Gegner-/Projektil-/Pickup-Dictionaries. XP-Merging auf 250 Juwelen erhält Gesamtwert. 42/42 automatisierte Prüfungen bestanden. Kataloge für C/D bereits erzeugt, aber noch keine Behauptung vollständiger Integration. Kein Parserfehler. Nächster Schritt: Truhen-/Runen-State-Machine, volle Run-Struktur und Navigation C.

## Phase C abgeschlossen
30 gewichtete Minutenwellen mit Skalierung und Spawn-Budget, Bossankunft 5/10/15/20/25/29, drei Bosse mit zwei Angriffen, 12 Evolutionen und 2 priorisierte Fusionen, historisch korrekte Boss-Truhenberechtigung, 8 funktionale Runen, Runensegen zu Beginn/11/21, zwei Arena-Pattern, Normal/Schnell/Fluch, HUD und Bossleben, Pause/Rezepte, Sammlung und Ergebnis. Szenen game/player ergänzt; Menüseiten werden als echte Controls zentral aufgebaut, statt leere Szenendateien zu vervielfachen.
Automatisierte Tests: alle damaligen Prüfungen bestanden, 0 FAIL; tatsächliches Pausieren des SceneTree und drei verkettete Modals geprüft. Import ohne Parserfehler.
Nächster Schritt: Phase D – persistenter Save, Shop, Unlocks, Einstellungen, Audio, Controller-/Langzeittests und Dokumentation.

## Phase D abgeschlossen – 2026-11-02

Implementiert: 4 Helden mit Werte-/Startwaffen-/Unlock-Varianten, dauerhafter JSON-Save mit Schema/Backup/atomarem Schreiben, 10 Meta-Upgrades mit gestaffelten Preisen, Erfolge/Unlocks, Sammlung/Bestiarium/Rezeptentdeckung, einmalige Goldbuchung mit Fluchbonus, Einstellungen (Audio, Fenster/Vollbild, Auflösung, Shake, reduziertes Blinken, Schadenstexte, Stick-Totzone, UI-Skalierung), synthetische Originalmusik und Effekte, Tastatur-/Controller-Fokus, 11 grafisch geprüfte Ansichten inklusive UI-Skalierung, Debugpfade nur in Debug-Builds. Gewichtete Laternenbeute liegt separat in resources/loot_table.tres. Truhen haben eine kurze, sofort überspringbare Überblendung.

### Finale Nachweise

- Engine: **4.7.2.stable.official.ed1daf0bf**, offizielle SHA512-SUMS.txt gegen heruntergeladenes ZIP geprüft. Kein Godot 3 oder systemweites 4.6.3 verwendet.
- Import-/Parsercheck: bestanden, keine Script-/Ressourcenfehler; final außerhalb der engen IPC-Sandbox ausgeführt. Log: test-results/import.log.
- **99 PASS / 0 FAIL**, keine Fehlerausgaben oder gemeldeten Leaks im finalen Testlauf. Log: test-results/unit.log. Enthält echte Szenen/Modalpause, isolierte Projektil-/Aura-/Orbit-/Beam-/Bombentreffer, Status-/Runenwirkungen, Inventar/Rezepte, XP/Gold und Save/Shop/Unlocks.
- Lasttest: **180 simulierte Sekunden, 5.400 Schritte**, 37,354 s CPU-Wandzeit; bis **380 Gegner / 261 Projektile / 300 Pickups**, 11.318 Kills, fehlerfreier Abbau. Log: test-results/stress.log. Last-Harness hält den Gegner-/Projektilbestand künstlich hoch und schützt den Spieler; kein Beleg menschlicher Gewinnbarkeit.
- Vollständiger **30-Minuten-Run** mit tatsächlichem Director/Kampf: **30:00, einmal Sieg, 3 Runen, 24.236 Kills**, 75,909 s Wandzeit. Log: test-results/full-run.log. Test-Harness wählt automatisch und gibt Immunität; Modal-UI separat geprüft.
- Grafischer Smoke-Test: 1280×720, Compatibility/OpenGL 4.5, Mesa llvmpipe, Xorg-Dummy. 11 Screenshots erzeugt; Hauptmenü/Arena im Repository. Echte KEY_D-Bewegung: ca. 143 px; simulierte JoypadMotion-Bewegung: ca. 69,8 px. Log: test-results/visual.log. Nur Treiberhinweis zu nicht unterstützter VSync-Umschaltung, keine Scriptfehler/Leaks.
- Messumgebung: Linux x86_64, AMD EPYC 7763, 5 sichtbare vCPUs, ca. 33 GiB sichtbarer RAM. Keine gerenderten 60 FPS behauptet; Simulation und grafischer Smoke-Test sind getrennte Nachweise.
- Wiederverwendbare Cloud-Felder `install_script` und `start_skill` gespeichert; Godot-Version, SHA512-Prüfung, XDG-Pfade und bestehender Checkout dokumentiert. Entwurf gespeichert, **nicht veröffentlicht**. Für Aktivierung in Umgebungseinstellungen prüfen/speichern und veröffentlichen.

### Bewusste Vereinfachungen und offene manuelle Abnahme

Geometrische Originalformen/Texticons statt gezeichneter Sprite-Sheets, einfache FX und kurze Ambientmusik. Keine leeren Pflicht-Stubs. Menüseiten sind reale Controls in scripts/app.gd, keine separaten leeren .tscn-Dateien. Siehe DESIGN.md.

Offen: physischer Controller, hörbare Audiobalance, native Fenster-/Vollbild-/DPI-Prüfung am Zielrechner, menschlicher 30-Minuten-Balancecheck, Release-Export/Laufzeittest. Kein bekannter ungelöster Parser- oder Laufzeitfehler in den ausgeführten Prüfungen. Tests garantieren keine perfekte Balance oder 60 FPS auf anderer Hardware.

### Nächste Session

1. README.md, DESIGN.md und BALANCE.md lesen; ausschließlich geprüfte 4.7.2-Engine verwenden.
2. `GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 ./tools/check.sh` ausführen.
3. Offene Hardware-/Spielgefühl-Punkte aus docs/SMOKE_TEST.md bearbeiten; Balanceänderungen in den zentralen Ressourcen dokumentieren. Für Gameplayänderungen danach `./tools/check.sh --long` mit derselben Engine.
4. Bestehenden isolierten Checkout verwenden, keinen Worktree ohne ausdrückliche Nutzeranweisung erzeugen. Engine/Dateien bleiben bestehen; virtuelle Display-/Spielprozesse aus einer alten Session nicht voraussetzen.
