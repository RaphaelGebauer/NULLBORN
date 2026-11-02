# Abnahmecheckliste

Automatisiert mit Godot **4.7.2.stable.official.ed1daf0bf**. Unit-/Integrationstests prüfen echte Model-, Szenen- und Combat-Implementierungen. Keine Fake-Ergebnisse und kein alternatives Testschnittstellen-Spiel.

| Prüfung | Nachweis / Status |
|---|---|
| Frischer Import und Parser | `tools/check.sh`, Importlog |
| Alle Kataloge und Rezeptverweise | Unit: Stückzahlen, sieben Leveländerungen und Abhängigkeiten |
| Standardheld, HP/XP/Slots/Angebote | Unit |
| Projektil, Aura, Orbit, Beam, Explosion | Isolierte echte Treffer, kein fremder Autoangriff aktiv |
| XP-Overflow, Dreierauswahl, Reroll/Skip/Banish | Unit |
| Fusion/Evolution und alte Truhe | Unit |
| Bosswellen 5/10/29, Sieg 30:00 | Unit + vollständige Simulation |
| Pause inklusive Kampfzeit, drei Modal-Events ohne Deadlock | SceneTree-Integrationstest |
| XP-Merging/Gold einmalig | Unit |
| Save, Settings, korruptes JSON, Shop, Unlocks | Unit mit separater temporärer Save-Datei |
| Hauptmenü → Held → Arena → Runensegen → Kampf | Grafischer Smoke-Test, echte Render-Screenshots |
| Tastaturbewegung | Grafischer Test mit eingegebenem KEY_D-Ereignis |
| Controller-Stick | Synthetisches JoypadMotion-Ereignis im grafischen Test |
| Level-up, Ergebnis, Shop, Sammlung, Einstellungen | Grafische Screenshots und Controls aufgebaut |
| 380 Gegner / 200+ Projektile über drei simulierte Minuten | `tests/stress_runner.gd` |
| 30-Minuten-Run bis Sieg, drei Runenereignisse, Entitätsabbau | `tests/full_run_runner.gd` |

Noch auf echter Zielhardware manuell durchführen:

- [ ] Physischer Controller: Stick, D-Pad-Fokus, A, Start; Reroll/Skip/Banish per Fokus.
- [ ] Hörprobe Musik/Effekte und Lautstärkeregler, Audio-Gerätewechsel.
- [ ] Vollbild/Fenster, mehrere Auflösungen und DPI-Werte am Desktop.
- [ ] Menschlicher Langzeit-Run mit Levelentscheidungen: Schwierigkeit, Lesbarkeit, Bossfairness.
- [ ] Manueller Build mit 6+6, Evolution nach 10, Runensegen 11/21; mehrere Runs und Shop.
- [ ] Release-Export: F6–F12 deaktiviert; Zielplattform-Laufzeittest.

Debugpfad zum schnellen manuellen Test ist in README beschrieben. Langzeitsimulationen benutzen künstliche Unverwundbarkeit und automatische Entscheidungen im Test-Harness, damit Kampf und Timer bis zum Ende geprüft werden; sie belegen keine menschliche Gewinnbarkeit oder ausgewogene Schwierigkeit.
