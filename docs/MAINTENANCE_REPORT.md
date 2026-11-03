# NULLBORN — Wartungsabschluss M1–M5

Prüfung: 2026-11-03, Godot **4.7.2.stable.official.ed1daf0bf**, GDScript 2.0, Compatibility-Renderer. Ausgangspunkt: `c0a6fc7`. Bestehendes Projekt weiterentwickelt; keine Neuerstellung, entfernten Features oder Änderungen an Spieltempo und Balance.

## Tatsächlich umgesetzt

| Phase | Änderung und wesentliche Dateien | Veröffentlichter Phasencommit |
|---|---|---|
| M1 | Discovery-Fixture isoliert und Modal-RNG kontrolliert (`tests/test_runner.gd`). Einheitliche Transaktionen mit Rollback und realen I/O-Fehlerprüfungen (`scripts/save_manager.gd`); sichtbare Fehler/Pending-Anzeige und Retry, gemeinsame Inventory-/Unlock-Speicherung (`scripts/app.gd`). | `a3222a5` |
| M2 | Genau Collection als read-only ScrollContainer mit Registry/Discovery-Callback extrahiert (`scripts/ui/collection_view.gd`). App behält Navigation, Modals und Lifecycle; bestehende Texte/Scrollstruktur bleiben erhalten. | `9f5b4b6` |
| M3 | Reine Affix-/Reaktionsdefinitionen unter `scripts/data/`, gemeinsame Konstantenobjekte für Registry und Gameplay-Helfer. Staging-only Generatorprüfung mit stabiler ID-Baseline und sieben Sicherheitstests (`tools/check_generated.py`, `catalog_ids.json`, `tests/test_generator_safety.py`). Überschriebene Dateien in [GENERATORS.md](GENERATORS.md) dokumentiert. | `cebf835` |
| M4 | Nur Zeichnen nach `scripts/world_renderer.gd` verschoben. World bleibt authoritative; synchron geliehene Sicht ohne gespeicherte Pool-Referenzen. World 602 → 510 Zeilen, Renderer 116 Zeilen. | `b7ee0dc` |
| M5 | Unbanked-Run darf bei Speicherfehler durch Main Menu/Try Again nicht verloren gehen. Nach Recovery Speicherung genau einmal vor Navigation. Quit hält bei fehlgeschlagenem Pending-Retry die Sitzung offen. Grafiktest wartet auf Abschluss des letzten Physikschritts statt zu früh zu messen. Dokumentation und vollständige Abnahme aktualisiert. | Commit mit diesem Bericht; finaler Remote-Hash in der Abschlussantwort |

Weitere betroffene Dateien: `tools/check.sh`, `tools/graphical_check.sh`, `.gitignore`, README, STATUS, DESIGN, AGENTS, Architekturbericht und Smoke-Anleitung. Neue Godot-Skripte besitzen ihre getrackten UID-Dateien; Logs und Bildschirmaufnahmen stehen unter `test-results/` und `docs/screenshots/`. Keine Zugangsdaten gespeichert.

## Tests und Nachweise

Alle folgenden Ergebnisse wurden während dieser Wartung ausgeführt, nicht aus dem alten E6-Bericht übernommen.

| Prüfung | Ergebnis |
|---|---|
| Import/Parser, exakt Godot 4.7.2 | Erfolgreich |
| Bestehende funktionale Suite | 976 PASS / 0 FAIL: 179 Basis/E1, 404 Mutationen, 103 Risse/Elite/Bosse, 111 Reaktionen, 90 Konstellationen, 40 Polish, 49 Katalog |
| Neue `maintenance_runner.gd` | 33 PASS / 0 FAIL; zusammen **1009 Godot-Funktionstests** |
| Generator-Sicherheitsfälle | **7 PASS / 0 FAIL**, Ausgabe in `generator-safety.log` |
| Wiederholte isolierte Unit-Läufe | Fünf × 179 PASS, Seeds 1/42/115/72047/115; `maintenance-seeds.log` |
| Native Grafiktests | **45 PASS / 0 FAIL** plus Mutations-/Riss-/Reaktions-Captures; 1280×720, 1600×900, 1920×1080 |
| Echter X11-Host mit `--wid` | **8 PASS / 0 FAIL**; keine Embedded-Resize-Meldungen |
| M4 Vorher-/Nachher-Renderer | Vier Assertions bestanden: reale Ausgabe, keine Zustandsänderung, pixelidentisch und gleiche Laufzeitdaten wie vor Extraktion; `render-m4.log` |
| Abschließende Renderer-Regression | Zwei Assertions bereits in den 45 nativen Prüfungen enthalten; `render-readonly.log` |
| Save-Kompatibilität | Alte Version-1-Fixture ergänzt additive Defaults und erhält Gold, Meta-Ränge, entdeckte Rezepte und Settings; Korrupt-/Reload-/Reset-Prüfungen bestanden |
| Generator-/Diff-Audit | 153 Ressourcen + neun generierte Skripte byteidentisch zur temporären Generierung, stabile IDs; kein Resource-/Projektsettings-Diff |

Neue Regressionen prüfen echte blockierte Dateiöffnungen und fehlgeschlagenes Umbenennen, unveränderte alte Datei, Wallet-/Rang-Rollback, Star-Kauf/Reset/Finish, Pending-Discovery vor Transaktionen, Retry/Reload/Idempotenz, UI-Fokus/Pause, Geheimhaltung der Collection, gemeinsame Definitionsobjekte sowie gesperrte Ergebnisnavigation/Quit bei Schreibfehlern. Der grafische Wartungsrunner ergänzt 18 Assertions; der Renderer-Runner prüft Gameplay-/RNG-/Pool-/Statistik-/Mutationscadence-Snapshots auf realen Renderframes.

Ein erster finaler Grafiklauf maß Controller-Bewegung mit 49.80 statt mindestens 50 Pixeln: `physics_frame` wird vor den Node-Callbacks emittiert, der letzte gezählte Schritt war noch nicht abgeschlossen. Fixture korrigiert durch Warten auf den folgenden Prozessframe, ohne die Distanzschwelle zu senken. Der komplette abschließende Grafiklauf danach besteht. Fehler-/Leak-Ausgaben dieses abgebrochenen Testlaufs sind kein Befund des finalen Spiels. Die finalen Logs enthalten keine Script-/Runtime-Fehler, FAILs oder geleakten Instanzen. Einzige verbleibende Engine-Warnung: llvmpipe unterstützt die angeforderte VSync-Umschaltung nicht.

### Vollständige Simulationen und Last

| Messung | Normal | Quick |
|---|---:|---:|
| Run-Zeit / Kampfsekunden | 30:00 / 1800 | 30:00 / 900 |
| Siege / Runen | 1 / 3 | 1 / 3 |
| Kills / Elites | 26,343 / 23 | 13,013 / 22 |
| Boss-Phase-II-Übergänge | 6 | 6 |
| Stabilisiert / überladen | 2 / 2 | 2 / 2 |
| Reaktionen | 18,490 | 8,809 |
| Tatsächlicher Schaden | 10,861,180.3878891 | 5,018,293.49359016 |
| Durchschnittlicher Kampf-DPS | 6033.98910438282 | 5575.88165954463 |
| Starlight / aktive Sterne | 8 / 18 | 8 / 18 |
| CPU-Wallzeit | 101.709 s | 50.629 s |

Beide vollständigen Logs stimmen mit `c0a6fc7` exakt überein, ausgenommen gemessene Wallzeit. Separate Katalog-/Mutationssuiten testen alle 15 Waffen, 45 Mutationen, Evolutionen und beide Fusionen; die automatisch gewählten Langlauf-Builds sind keine vollständige Permutation aller Inhalte.

Stress: 5400 Schritte / 180 simulierte Sekunden, Spitzen **382 Gegner, 261 Projektile, 300 Pickups**, 12,585 Kills, 7,186 Reaktionen; 51.381 s CPU-Wallzeit. Bestehende Proc-/FX-/Hazard-Budgets bestehen unverändert.

Befehle: isolierte XDG-Verzeichnisse, `./tools/check.sh --long`; Quick separat mit `STERNENBRUCH_QUICK_TEST=1` und `tests/full_run_runner.gd`; `DISPLAY=:99 ./tools/graphical_check.sh`; anschließend dieselbe Grafikprüfung mit `--wid` und real ermittelter Host-ID. Keine echten Spielersaves benutzt. `maintenance-audit.log` hält Baseline-/Fehlerprüfung fest. Betrachtete neue Aufnahmen: Collection bekannt bei 1280, Pending-Ergebnis bei 1280 und Renderer-Fixture; weitere Auflösungen automatisiert geprüft und gespeichert.

## Erhaltene Verträge und bewusst verschobene Arbeit

Save-Version 1 und alle gültigen Daten bleiben erhalten. Kauf/Reset/Banking sind transaktional; bereits verdiente Discovery/Settings bleiben bei Storage-Ausfall sichtbar pending. Ein nicht beschreibbarer Datenträger kann RAM-Fortschritt bei erzwungenem Prozessende oder Absturz weiterhin verlieren. Es wird keine nicht erfolgte Speicherung als Erfolg dargestellt.

App bleibt Run-/Pause-/Modal-Owner; Settings und andere gekoppelte Ansichten wurden nicht gleichzeitig ausgelagert. World behält Treffer-/Tod-/Drop-Reihenfolge, Pools, Spatial Hash, AI und Feedback-Updates. Der Renderer hält keine Referenzen für spätere Frames und ändert keine Cadence oder RNG. Keine neue zweite Berechnung oder doppelte Bonusanwendung.

Aus Sicherheitsgründen keine breite Damage-/AI-/Pool-Neuarchitektur, keine komplette UI-State-Machine und keine Verschiebung der Feedback-Timer/Kamera-Updates. Langfristig sinnvoll: weitere reine Ansichten einzeln extrahieren; Dictionary-Schemata/Pool-Reset-Verträge dokumentieren und gezielt typisieren; kanonische strukturierte Mutationsdaten mit stabilen IDs statt Markdown-Reihenfolge einführen. Diese Aufgaben benötigen eigenen Umfang und Nachweise.

Automatische Simulationen verwenden Immunität und automatische Entscheidungen; Software-Rendering und synthetische Controller-Eingaben beweisen keine menschliche Balance, Hardware-FPS oder physische Controller-Kompatibilität. Offen bleiben echte Geräte/Audio, Desktop-Editor/DPI/Window-Manager, Release-Export und menschlicher vollständiger Run.

Alle Phasen werden auf `main` ohne Force-Push veröffentlicht. Vor jedem Push Remote-Abgleich; abschließend unabhängiger frischer Bare-Clone mit Ref-/Dateibaumprüfung. Der endgültige verifizierte GitHub-Commit wird in der Abschlussantwort angegeben.
