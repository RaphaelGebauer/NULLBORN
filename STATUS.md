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
Automatisierte Tests: 69 PASS, 0 FAIL; tatsächliches Pausieren des SceneTree und drei verkettete Modals geprüft. Import ohne Parserfehler.
Nächster Schritt: Phase D – persistenter Save, Shop, Unlocks, Einstellungen, Audio, Controller-/Langzeittests und Dokumentation.
