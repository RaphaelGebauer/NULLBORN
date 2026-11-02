# STERNENBRUCH – Fortschritt

Ziel: ausschließlich Godot 4.7.2 Stable, GDScript 2.0. Spezifikation: CODEX_MASTERPROMPT.md.

## Phase A
Implementiert: Projekt, Menü, CharacterBody2D + Kamera, offene Arena, zwei Gegner, Auto-Projektil, HP, XP/Overflow, drei Upgrade-Karten, Pause, Ergebnis/Neustart.
Validierung läuft; weitere Phasen noch offen.

Nächster Schritt: Phase-A-Import und automatisierte Tests mit verifiziertem Godot 4.7.2, danach Kampfbasis B.

Phase A validiert mit Godot 4.7.2.stable.official.ed1daf0bf: 7/7 automatisierte Prüfungen bestanden (Startstats, XP-Kurve, Overflow/Queue, drei Karten, Heal-Cap, echter Projektil-Kill, Tod/Ergebnis). Parserfehler behoben. Fokus-Callback gegen inzwischen entfernte Controls abgesichert. Editor-Socketwarnungen entstehen durch Sandbox-Netzwerksperre.
