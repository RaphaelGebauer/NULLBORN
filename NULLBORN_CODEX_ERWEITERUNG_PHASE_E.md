# CODEX MASTER-AUFTRAG – NULLBORN / STERNENBRUCH – ERWEITERUNGSPAKET E

**Dieser gesamte Text ist ein ausführbarer Arbeitsauftrag an Codex. Bitte direkt im EXISTIERENDEN GitHub-Repository `RaphaelGebauer/NULLBORN` umsetzen. Nicht als Designvorschlag beantworten!**

## 0. Rolle, Kontext, absolute Grenzen

Du bist Senior Game Designer, Senior Godot-4-Entwickler, Gameplay-Programmierer und QA-Engineer. Arbeite auf dem **vorhandenen, bereits spielbaren Godot-Projekt** `STERNENBRUCH` im Repository `https://github.com/RaphaelGebauer/NULLBORN`. Füge Features hinzu, ohne das Projekt neu aufzubauen oder bestehende Inhalte zu löschen.

**Zielplattform: GODOT 4.7.2 STABLE, GDScript 2.0, Godot-4-Szenen und -APIs. Auf keinen Fall Godot 3.** Kein `KinematicBody2D`, kein `yield`, keine Godot-3-TileMap- oder Tween-Syntax, keine veralteten Signaturen. Verwende vorhandene `CharacterBody2D`, Ressourcen, Pooling, UI und den Compatibility Renderer weiter. Keine fremden Assets, bezahlten Plugins, .NET-/C#-Abhängigkeiten, Online-Dienste oder Copyright-Inhalte. Alle sichtbaren Spieltexte bleiben **Englisch** (das ist eine bereits umgesetzte Projektentscheidung), Kommentare/Dokumentation dürfen Deutsch oder Englisch sein. Gamepad, Maus/Tastatur, Skalierung und Offline-Spielbarkeit erhalten.

**Vorher lesen:** `README.md`, `STATUS.md`, `DESIGN.md`, `BALANCE.md`, `docs/SMOKE_TEST.md`, `project.godot`, relevante Tests sowie den Code von `scripts/app.gd`, `scripts/run_model.gd`, `scripts/world.gd`, `scripts/combat.gd`, `scripts/save_manager.gd` und `scripts/data/registry.gd`. Nur ergänzen, wo sinnvoll. Maßgeblich ist der tatsächliche Stand des Checkouts, nicht dieser Text als Behauptung über unveränderliche Dateien.

**Aktueller Ausgangsstand laut Repository bei Erstellung dieses Auftrags:** 15 Grundwaffen, 17 Passivitems, 15 Evolutionen, zwei Fusionen (`dusk_storm`/`day_night`), vier Charaktere, zwei Arenen, 30 Minutenwellen, drei Boss-Typen (`astral_guardian`, `void_queen`, `storm_core`), sechs Waffen- und sechs Passivslots, vorhandene Boss-Truhen-Evolutionen, Reroll/Skip/Banish, 20 permanente Meta-Upgrades, Save-Datei `user://savegame.json`, Collection, automatisierte Tests. **Diese Features dürfen nicht verloren gehen.** Bestehende Balancing-/Pacing-Konfiguration `resources/pacing.tres` unangetastet lassen, sofern nicht technisch nötig; die bewusst langsame Startphase (8 Minuten Ramp-up) beibehalten.

### Exakt diese Erweiterungen umsetzen

1. Dynamisches **Riss-Instabilitäts-System** (Instability/Rift Instability).
2. **Waffenmutationen bei Waffenlevel 4**, die vollständig mit normalen Evolutionen und beiden Fusionen zusammenarbeiten.
3. **Elite-Gegner mit zufälligen Affixen**, sauberen Limits und zusätzlichen Belohnungen.
4. **Drei Bossarten mit klaren, fairen Mehrphasen-Kämpfen** (bestehende Bosse ausbauen).
5. **Elementare Trefferreaktionen** zwischen kompatiblen Elementen.
6. Separater, permanenter **Sternenkonstellations-/Star-Map-Skilltree** (18 konkrete Knoten).
7. **Sehr dezentes Trefferfeedback**: Mikro-Hitflash, leichtes Trefferfeedback, kaum Kamerabewegung.
8. **Detaillierter Endbildschirm** mit echter Schadensstatistik.
9. **Build-Vorschau** im Pausenmenü einschließlich aktiver Modifikatoren und versteckter Rezeptlogik.

**Nicht umsetzen:** neue spielbare Begleiter, Ultimates, Fraktionen, neue Biome/Arenen, zerstörbare Umgebung, eigenständige Zufalls-Eventketten, Mini-Missionen, tägliche Challenges, neue Truhen-Seltenheiten, Endlosmodus, Skins, neue Charakter-Spezialisierungen, neue Relikt-Slots, weitere normale Grundwaffen oder weitere Grund-Passivitems. Das hier ist ein fokussiertes Erweiterungspaket, kein Neustart.

---

## 1. Entwicklungsregeln und Vorgehen

1. Zuerst die reale Architektur und vorhandene API prüfen. Plane inkrementelle Erweiterungen; keine neue zweite Combat-/Save-/Event-Engine parallel zum bestehenden System.
2. Alle Zahlen als Konfiguration/Definitionsdaten und zentrale Konstanten halten, nicht verstreut hart codieren. Neue Ressourcentypen/Definitionsdaten in `scripts/data/` und `resources/` sind erlaubt. Das bestehende Registry-Konzept weiterverwenden; bei neuen Katalogen Registry-Validierung und Fehlerberichte erweitern.
3. `tools/generate_data.py` überschreibt erzeugte `.tres`-Definitionen. Jede Änderung an generierten Definitionen **auch im Generator** hinterlegen oder einen sauber dokumentierten eigenständigen, vom Generator unberührten Datenpfad verwenden.
4. Nur eine Wahrheit je Spielzustand. Keine UI-eigenen Fake-Zähler. Neue Kampfwerte dürfen die unveränderlichen Weapon-Resource-Definitionen nicht mutieren (`duplicate(true)` für Runtime-Werte).
5. Schäden und Procs müssen eindeutig einer Quelle zugeordnet werden. Schutz gegen Proc-Rekursion, Pooling-Leaks, zu viele Projektile, modale Race Conditions und mehrfach gebuchte Endbelohnungen.
6. Alte Spielstände **verlustfrei migrieren/ergänzen**. Gold, alle 20 bestehenden Meta-Upgrades, Freischaltungen, Bestzeiten, `seen`, `evolved_recipes`, Settings und Achievements erhalten. Beim Laden fehlende neue Felder mit Defaults ergänzen; kein Reset, kein Löschen, keine Save-Version ohne Migration anheben. Bei kaputten Saves bisheriges Backup-Verhalten erhalten.
7. Neue Inhalte brauchen echtes UI, echte Integration, echte Tests, echte Dokumentation. Keine Platzhalter-Buttons, keine reinen Kommentare, keine `TODO: implement later` für Pflichtfeatures.
8. In logischen Phasen arbeiten, nach jeder Phase Tests durchführen, Fehler beheben und sinnvolle Git-Commits erstellen; nach Abschluss mit vorhandenen Berechtigungen auf GitHub veröffentlichen, **ohne Force-Push**. Falls Push nicht erlaubt: konkreten Fehler anzeigen und lokal gesicherten Commit-Stand benennen. Niemals einen nicht überprüften Push als erfolgreich melden.
9. Bei Zielkonflikten Priorität: vorhandener Spielstart + Save-Verträglichkeit + funktionsfähiger Kampf + bestehende Evolutionen + flüssiger 30-Minuten-Run vor visueller Verzierung.

---

## 2. RISS-INSTABILITÄT / RIFT INSTABILITY

### 2.1 Grundregel

Neuer Laufzeitwert `instability: float` in `run_model.gd`, begrenzt auf **0–100**, Startwert **0**. UI-Bezeichnung `Rift Instability`. Fortlaufender Grundanstieg **+0,03 pro realer Simulationssekunde** bzw. pro 1 Sekunde normaler Run-Zeit (bei Quick Mode ausdrücklich an die **In-Game-Run-Zeit**, nicht an die reale Wandzeit koppeln). Implementiere eine konsistente `run_delta`-Definition; `fast` darf nicht Instability-, Wave- oder Boss-Schedule auseinanderlaufen lassen. Ein normaler 30-Minuten-Run gewinnt dadurch 54 Punkte, sofern nichts Weiteres passiert. Boss-Kill: **+4 Instabilität**, Elite-Kill: **+0,5**, jeweils begrenzt durch `clampf`. Nicht auf gewöhnliche Kills skalieren! Die aktive Spielerentscheidung an einem Rissknoten ist die Hauptmöglichkeit, Instabilität zu steuern.

Neue Signals `instability_changed` und gegebenenfalls `instability_band_changed`. UI: kleine, lesbare, farblich graduierte HUD-Anzeige mit Zahlenwert und aktuellem Band; im Pausen-/Build-Menü detailliert erklären. Kein riesiges Overlay auf der Spielfläche.

### 2.2 Vier definierte Schwierigkeitsschwellen

Die Effekte sind **kumulative Tabellenwerte pro Band**, niemals wiederholt auf Grundwerte multiplizieren:

| Aktueller Wert | Band | Spawn-Dichte | Gegnergeschwindigkeit | Gegner-Kontaktschaden | Bonus auf Boss-/Elite-Gold |
|---|---|---:|---:|---:|---:|
| 0–24,99 | Dormant | ×1,00 | ×1,00 | ×1,00 | +0 % |
| 25–49,99 | Stirring | ×1,05 | ×1,03 | ×1,00 | +10 % |
| 50–74,99 | Fractured | ×1,12 | ×1,06 | ×1,08 | +20 % |
| 75–89,99 | Unstable | ×1,20 | ×1,10 | ×1,12 | +30 % |
| 90–100 | Critical | ×1,25 | ×1,12 | ×1,20 | +40 % |

Diese Faktoren an das **bestehende** Wave-/Curse-/Pacing-System anhängen; sie ersetzen keine Minutenskalierung. Geschwindigkeitsfaktoren aus einem aktuellen zentral berechneten Zustand ableiten, nicht direkt in Gegnerstatistik hineinakkumulieren. Caps für lebende Gegner/Projektile beibehalten. Goldbonus nur für tatsächlich durch Boss-/Elite-Belohnung erzeugtes Gold, nicht pauschal für alle Goldsources. Bänder dürfen vor- und zurückwechseln. Deutliche Warnung beim erstmaligen Eintritt ab 75 (kleiner Banner + Sound), keine wiederholten Warnungen bei Schwellenflattern (Hysterese / Cooldown).

Ab Band `Fractured` Chance auf Elite-Gegner leicht erhöhen; ab `Unstable` Chance auf maximal zwei Elite-Affixe; ab `Critical` auf maximal drei (siehe Elite-System). Das führt niemals zu unbegrenztem Elite-Spam.

### 2.3 Interaktive Rissknoten (nur als Bestandteil dieses Systems)

Genau **vier Rissknoten-Slots pro Run** bei ungefähr **06:00, 12:00, 18:00, 24:00** Spielzeit. Jeder erscheint nahe, aber nicht auf dem Spieler, mit gut lesbarem Marker; niemals direkt in Boss-/Feindkollisionen erzeugen, nicht mehrfach anlegen. Ein Knoten bleibt **bis zu 90 Run-Sekunden** aktiv oder bis er gewählt wird; verschwunden bedeutet kein späteres Nachholen. Eine Interaktionsaktion `interact` mit **F** sowie Gamepad-konformer Schaltfläche anbieten (vermeide Konflikte mit vorhandenen Inputs). In einem Umkreis von maximal 90 px darf der Spieler einen Knoten aktivieren. Während der Entscheidungs-UI muss das Spiel pausiert werden; Priorität gegenüber Level-Up/Rune/Chest sauber in die bestehende Modal-Queue einordnen. Nur echte Nähe erlaubt Interaktion; UI nicht automatisch über Spieler aufpoppen lassen.

**Auswahl aus genau zwei klar beschrifteten Optionen:**

- `Stabilize Rift`: −20 Instabilität, +10 % Max-HP als Heilung (kein Überheilen); bei 0 Instabilität weiterhin zulässig, Wert clampen.
- `Overcharge Rift`: +20 Instabilität, einmalig **+120 × (1 + Run-Minute / 30)** Gold, auf sinnvolle ganze Zahl runden, **zusätzlich XP im Wert von 35 % der zu diesem Zeitpunkt benötigten nächsten Stufe** ohne doppeltes Growth-Multiplizieren. Belohnungen sind echt und werden sofort gutgeschrieben. Kein kostenloser Boss-Chest-Spawn und **keine Umgehung der Evolutions-Truhen-Voraussetzung**.

Knoten verschwinden nach Wahl genau einmal. Kein eigenständiges Altar-Missions-/Zufalls-Eventsystem hinzufügen.

### 2.4 Fairness, Darstellung und Test

Außerhalb des HUD nur subtile Hintergrundtönung oder gelegentliche kleine geometrische Partikel bei hohen Bändern. Kein dauerhafter Bildschirmfilter, kein aggressives Blinken. Im Endbildschirm `Peak Instability`, `Final Instability`, `Rifts Stabilized`, `Rifts Overcharged` anzeigen. Teste Grenzwerte (0, 24,99/25, 49,99/50, 74,99/75, 89,99/90, 100), Quick Mode, unterschiedliche Entscheidungsreihenfolgen und 30-Minuten-Simulation.

---

## 3. WAFFENMUTATIONEN – UND TROTZDEM ALLE EVOLUTIONEN BEHALTEN!

**Dies ist die wichtigste Designvorgabe.** Mutationen sind **zusätzliche Spezialisierungen einzelner Waffen**, keine Ersetzung für Evolutionen. Weder das gewählte Mutationssystem noch ein evolutioniertes Item darf den anderen Mechanismus blockieren.

### 3.1 Grundprinzip: drei Schichten pro Waffe

**Schicht A – Basiswaffe:** Bestehender Waffenlevel **1 bis 8** mit bisherigen Werten und Upgrade-Optionen.

**Schicht B – Mutation/Imprint:** Wenn eine Basiswaffe **zum ersten Mal Level 4 erreicht**, startet direkt nach dem normalen Level-Up eine **separate Auswahl aus genau drei Mutationskarten** speziell für diese Waffe. Die Zeit steht still. Eine Karte muss gewählt werden; sie kostet **keinen zusätzlichen Level-up-Punkt**, belegt **keinen Waffen- oder Passivslot**, ist **kein Passivitem** und ändert nicht den Waffenlevel. Die gewählte Mutation ist danach für die aktuelle Waffe dieses Runs festgelegt und sichtbar; pro Basiswaffe höchstens eine. Anschließend geht die nächste bestehende Modal-Nachricht korrekt weiter. Bei mehrfachen XP-Level-ups mehrere Mutationsentscheidungen in FIFO-Reihenfolge, genau einmal je betroffener Waffe. **Wichtig bei der bestehenden `events`-Queue:** Die Mutation direkt nach der Level-Up-Karte ausführen, die die Waffe auf Lv4 bringt (gezieltes Einfügen vor bereits wartenden weiteren Level-Up-Modals), ohne bereits geplante andere Modals zu verlieren. Kann ein Run die Lv4-Schwelle überspringen, wird die Mutation trotzdem angeboten. Reroll/Skip/Banish gelten **nicht** für Mutationskarten; ESC/Controller-Back darf die Auswahl nicht abbrechen oder das Spiel entriegeln.

**Schicht C – Evolution:** Bestehende Regel **UNVERÄNDERT**: Basiswaffe mindestens **Level 5**, zum Rezept passives Item **Level 5**, Boss-Truhe von einem Boss, der **ab 10:00 gespawnt ist**; bei Fusion zwei Basiswaffen auf Lv5+, erforderliches Passiv Lv5, Fusionen haben Vorrang. Bestehende `model.evolution(eligible)`-Logik gezielt erweitern statt austauschen. Erreichte Level-4-Mutation wird über die Evolution **mitgenommen**.

**Beispiel normal:** `Arcane Needle Lv4` → wähle `Split Filament` → verbessere `Arcane Needle` mindestens auf Lv5, `Power Core` auf Lv5 → öffne berechtigte Boss-Truhe → `Star Piercer + Split Filament Imprint`. Das evolutionierte Star Piercer erhält die passende Mutation und kann normal weiterkämpfen. Passive bleibt ausgerüstet. Weder die Mutation noch das Erreichen von Lv4 löst eine Evolution selbstständig aus.

### 3.2 Vererbungs- und Fusionsregeln (explizit implementieren)

- Für eine **einfache Evolution** übernimmt das Resultat die vollständige Mutation der Ursprungswaffe. Das Resultat benutzt das evolutionierte Kampfverhalten und seine evolutionierten Stats; der Mutationseffekt wird **im gemeinsamen Kampf-/Treffer-Hook** angewandt und darf diese Werte ergänzen, nicht überschreiben.
- Für eine **Fusion** (`dusk_storm` = `ash_bow` + `frost_shard`, `day_night` = `moon_blade` + `sun_beam`) werden die Mutationseinträge beider Basiswaffen übertragen. Der Imprint der **ersten in `recipe.values.bases` genannten Waffe** wirkt mit **100 %** seiner Stärke (`primary imprint`), der zweite mit **50 %** (`echo imprint`). Eine noch unmutierte Waffe liefert keinen Imprint. Die Fusion belegt nach wie vor **einen** Waffenslot, beide Basiswaffen werden entfernt und das Katalysator-Passiv bleibt. Der Spieler sieht beide vererbten Mutationsnamen samt `Echo 50%` im Build-Menü.
- *Alle Mutationseffekte* benötigen eine konkret definierte, im Kampfsystem nachvollziehbare Skalierung für den Echo-Faktor. Bei quantisierten Effekten (z. B. „+1 Projektil“) statt `round(0,5)` einen deterministischen Trigger über Angriffe verwenden: Echo löst bei jedem zweiten geeigneten Angriff/Hit aus. Bei Effekten mit Cooldown wähle halbe Auslösungswahrscheinlichkeit oder doppelten Cooldown, **keine per Frame neu gerollte 50%-Chance**.
- Alle Imprints sind entweder als **angriffsbasiert**, **on-hit**, **periodisch** oder als **Werte-Modifikator** definiert. Jeder Effekt muss zu mehreren Angriffsbehaviors kompatibel sein. Wenn das Rezept den Attack-Behavior-Typ verändert, implementiere einen **funktional gleichwertigen, sicher begrenzten Ersatz**: etwa `extra projectile` → `secondary pulse` bei Aura/Orbit/Beam, `on projectile expiry` → `on effect end`. Nicht stillschweigend ignorieren. Teste jede Mutation mindestens gegen ihre normale Evolution; besonders die beiden Fusionen.
- Bei `Dusk Storm` oder `Day and Night` zählen weiter nur die echten Basiswaffen und Passiv-Voraussetzungen. Mutationen werden **nicht** in `model.weapons` als eigene Items gespeichert, sondern z. B. als Map `weapon_mutations[weapon_id]` mit kompatibler Datenstruktur für evolved/fused weapons. Ressourcen nicht mutieren. Die Collections-/Recipe-Sichtbarkeit wird nicht durch Auswahl der Mutation freigeschaltet.
- Wichtig: Waffen, die bereits auf Level 4 oder höher beginnen (z. B. Debug-Setup), müssen sauber ihre ausstehende Mutation erhalten oder per explizitem Test-/Debug-Helfer initialisiert werden. Debug-Konfigurationen nie auf normale Runs übertragen.

### 3.3 Exakte Liste: 15 Grundwaffen, jeweils drei Mutationen (45 Optionen)

**Benutze die bestehenden Weapon-IDs, nicht umbenennen.** Drei explizit unterschiedliche, im Gameplay sichtbare und programmierbare Optionen pro Waffe; folgende Werte als anfängliche Balance, wo notwendig im Rahmen der bestehenden Schadens-/Cooldown-Caps korrigierbar:

| Grundwaffe | Mutation A | Mutation B | Mutation C |
|---|---|---|---|
| `arcane_needle` | **Split Filament:** jeder vierte Angriff erzeugt ein zusätzliches Projektil mit 50 % Basis-Hitschaden (keine Proc-Kaskade) | **Hunter Thread:** +15 % Schaden am nächsten Gegner/Primärziel des Angriffs | **Star Mark:** Treffer markieren Ziel 3 s, auf markierte Ziele +8 % Waffenschaden (nicht mit bestehender `mark`-Implementierung doppelt anwenden) |
| `ash_bow` | **Cinder Trail:** 25 % Trefferchance auf Burn für 3 s | **Piercing Embers:** +1 Durchschlag, wenn Behavior kompatibel; sonst jede vierte Attacke ein kleines Sekundär-Puls-Hit | **Quickdraw:** −12 % Angriffscooldown dieser Waffe |
| `spark_orbit` | **Aurora Pulse:** alle 4 s kleine Puls-AoE mit 25 % Waffenschaden | **Outer Orbit:** +12 % Orbit-Radius | **Static Touch:** jeder fünfte erfolgreiche Treffer elektrisiert einen nahen zweiten Gegner für 35 % Schaden |
| `thorn_halo` | **Venom Thorns:** Halo-Treffer fügen 3 s Poison hinzu | **Briar Guard:** nach erlittenem Kontakt-Treffer 2-s-interner Cooldown, 30 % Waffenschaden als Gegenpuls | **Blood Sap:** max. 1 HP Heilung pro 25 tatsächlich verursachte Treffer, maximal 3 HP pro Minute |
| `lightning_call` | **Forked Current:** +1 Kettenziel, niemals mehr als insgesamt 4 zusätzliche Ziele | **Conductor:** +15 % Schaden gegen bereits verlangsamte Ziele | **Thunder Bind:** 15 % der Treffer verlangsamen ein Ziel 1 s, Boss-Slow halbiert |
| `moon_blade` | **Crescent Chill:** 20 % Trefferchance auf kurze Verlangsamung | **Twin Moon:** jeder dritte Angriff erzeugt eine weitere Klinge/Puls mit 40 % Schaden | **Lunar Momentum:** +10 % Rotations-/Bewegungsgeschwindigkeit dieser Klingen, kein Einfluss auf Spielerbewegung |
| `frost_shard` | **Glacier Bloom:** Treffer gegen gefrorene Ziele erzeugen alle 2 s max. kleine 45-px-AoE mit 35 % Schaden | **Whiteout:** Slow-Dauer +35 %, Freeze-Dauer bei Bossen nicht erhöhen | **Shardsplit:** jeder vierte Angriff +1 Fragment / sekundärer Puls mit 45 % Schaden |
| `storm_bomb` | **Rolling Thunder:** Wirkungsradius +15 % | **Second Impact:** jeder dritte Angriff detoniert nach 0,25 s ein zweites Mal mit 35 % Schaden | **Charged Air:** Treffer wenden einen kurzen elektrischen Zustand für Element-Reaktionen an |
| `shadow_fan` | **Night Volley:** jeder vierte Angriff ein weiteres schwaches Projektil/Signal mit 45 % Schaden | **Withering Cut:** +15 % Schaden gegen markierte Ziele | **Dark Reach:** +15 % Effekt-Reichweite/Projektilgeschwindigkeit je nach Behavior |
| `sun_beam` | **Sunburn:** Beam-Ticks erzeugen oder erneuern Burn mit begrenzter Rate | **Prism Ray:** alle 4 s ein schwächerer Zusatzstrahl/Sekundärpuls mit 30 % Schaden | **Solar Focus:** +12 % Strahlbreite/effektiver Hit-Radius, nicht zusätzlich normale globale Area mehrfach anwenden |
| `soul_well` | **Lingering Well:** Zone-/Effektdauer +20 % | **Soul Snare:** Treffer verlangsamen kurz, pro Ziel 1 s Refresh-Cooldown | **Echo Well:** jeder vierte erfolgreiche Tick löst 30 % Bonus-Hit aus |
| `meteor_rain` | **Comet Shards:** jeder vierte Einschlag erzeugt zwei kleine Sekundärtreffer mit je 25 % Schaden, maximal zwei weitere Ziele | **Afterglow:** Einschlag hinterlässt kurze 1-s-Burn-Zone mit insgesamt maximal 30 % Hit-Schaden | **Impact Wave:** minimaler kontrollierter Knockback auf normale Gegner, bei Bossen nur optisch |
| `prism_disc` | **Extra Facet:** +2 Ricochets, vorhandene distinct-target-Regel bewahren | **Reflective Edge:** +10 % Treffer-Schaden nach erstem Ricochet, einmal pro Bounce | **Crystal Burst:** am Ende jedes dritten Disc-Lebens ein kleiner Puls mit 35 % Schaden |
| `gravity_mine` | **Twin Charges:** jeder vierte Minen-Wurf eine Zusatzmine mit 40 % Schaden | **Dense Core:** +20 % Pull-Stärke, nicht auf Bosse wirken lassen | **Residual Gravity:** nach Explosion eine 1,5-s-Slow-Zone mit maximal 25 % Gesamtschaden |
| `reaper_gaze` | **Long Stare:** +15 % Hit-Radius | **Last Judgment:** +15 % gegen Feinde unter 35 % HP, **nicht** erneut den bestehenden ×3-Execute auf demselben Hit multiplizieren | **Soul Chain:** jeder vierte Kill mit dieser Waffe fügt einem zusätzlichen nahen Gegner 35 % Schaden zu |

**Technische Umsetzungshinweise:** Wo eine einzelne Mutation nicht ohne neue komplexe projektilbezogene Zustandsmaschine möglich ist, baue den Effekt in `combat.gd`/`world.gd` über ein generisches, gekapptes Secondary-Hit-/Periodic-Effect-System um, das dieselbe taktische Wirkung zuverlässig erzeugt. Nichts darf nur im Tooltip existieren. Einheitliche Meldung `Mutation Awakened: <name>`. Stats-/Build-Display muss auch die Evolution mit vererbter Mutation korrekt beschreiben. Der Spieler darf nach Evolution nicht erneut eine Mutationsauswahl auf Level 4 bekommen. Bei Fusion niemals verlorene oder verwaiste Mutationseinträge.

### 3.4 UI- und UX-Regeln für Mutationen

Die drei Karten zeigen: Waffenname, Mutationsname, präzise Effektbeschreibung, ggf. Element-Tag und das Label `Carries into Evolution`. Nach Wahl kurzer positiver Ton und äußerst dezenter Effekt. Controller-/Keyboard-Navigation wie bestehende Levelkarten, Auswahl über 1/2/3. Unter Pause/Build `Weapon Lv4+ · Mutation: ...`, bei Evolution `Evolved · Mutation inherited`, bei Fusion `Primary + Echo`. Der Evolutionstext zeigt weiterhin **nur entdeckte** Rezepte; kein Spoiler durch die Mutation!

---

## 4. ELITE-GEGNER MIT AFFIXEN

Elite ist eine **zusätzliche Variante eines vorhandenen Nicht-Boss-Gegners**, nicht ein neuer dauerhaft spammender Gegnertyp. Bestehendes `elite_hunter` als eigenständiger Gegner bleibt unangetastet. Nutze `elite: bool`, `affixes: Array[String]`, ein Elite-Farbschema, leicht vergrößerten Ring und eine dezente Affix-Kennzeichnung.

### 4.1 Spawn und Skalierung

- Erst ab **05:00**; initial im Durchschnitt **ein Elite-Spawn alle 70–90 Run-Sekunden**, ab Minute 15 alle 55–75 Sekunden, ab Minute 25 alle 45–65 Sekunden, deterministisch per Run-RNG und Spawn-Director. Kein Elite bei jedem normalen Spawn-Roll. Ein aktueller Run kann auch wenige Elites generieren, aber keine endlosen Wiederholungen durch Frame-Rolling.
- Es dürfen **maximal 2 normale Elite-Gegner gleichzeitig** leben; bei `instability >= 75` maximal **3**, zusätzlich zu Bossen. Der globale Enemy-Cap bleibt gültig.
- Elites auf Nicht-Boss-Gegner-Typen begrenzen, die dem Spieler in der aktuellen Minute tatsächlich begegnen können. Nicht aus Spawnkindern, Splittern, Boss-Summons und nicht aus Bossen selbst entstehen lassen.
- Grund-Elite: **×2,5 HP**, **×1,15 Schaden**, **×1,06 Geschwindigkeit**, **×2,0 XP**, **+45 Gold** beim Tod (plus Instabilitäts-Goldbonus). Diese Faktoren **auf bereits minutenskalierte Grundwerte**, nicht auf Monster mit wiederholt akkumulierten Multiplikatoren. Bei mehr Affixen HP höchstens ×3,5 und Schaden höchstens ×1,35 gegenüber normaler Version.
- 05:00–14:59 genau ein Affix; 15:00+ bei Instabilität ab 75 Chance auf zwei; ab 25:00 und Instabilität mindestens 90 Chance auf drei, ansonsten maximal zwei. Keine identischen Affixe. Keine Kombination, die einen Gegner unverwundbar macht oder Hard-CC dauerhaft verkettet.

### 4.2 Sieben konkrete Elite-Affixe

1. `Armored` – 20 % reduzierter eingehender Schaden (nicht zusätzlich unlimitiert stapeln).
2. `Swift` – +18 % eigene Laufgeschwindigkeit, Maximalgeschwindigkeit begrenzen.
3. `Volatile` – nach Tod 0,75 s gut sichtbare **orange** Warnzone 85 px, danach einmalige Explosion für 14 Basisschaden × bestehender Minutenskalierung; nie sofort unsichtbar detonieren.
4. `Vampiric` – heilt sich bei einem erfolgreichen **Kontakt-Hit am Spieler** um 5 % der eigenen Max-HP, maximal alle 3 s; nicht durch theoretischen Schaden während Spieler-iFrames.
5. `Blinking` – teleportiert sich höchstens alle 7 s 100–150 px seitlich, niemals direkt auf den Spieler oder in den Spieler-Hitbox-Radius; mindestens 0,3 s sichtbares Vorzeichen.
6. `Hexbound` – alle 6 s einen langsam fliegenden, lesbar gezeichneten Feind-Schuss; bestehendes Projektil-Cap beachten.
7. `Regenerating` – 0,35 % Max-HP pro Sekunde, außer für 3 s nach erhaltenem Feuerschaden; nicht mit Vampiric kombinieren, wenn dies zu unendlichen Kämpfen führt.

Alle aktiven Affixe beeinflussen wirklich AI/Schaden/Drops und werden im Build-/Run-Log als Namen erfasst. Affixe dürfen Boss-Verhalten nicht überschreiben. Neuer Test: Eine Explosion darf nicht aus einem wiederverwendeten gepoolten Gegner-Dictionary später erneut auslösen.

### 4.3 Belohnung und Lesbarkeit

Beim Elite-Kill: echtes Gold, XP und **15 % Chance auf ein kleines zusätzliches Heilungs-Pickup** (keine Evolutionstrühe!). Goldbonus der Instabilität berücksichtigen. Spieler sollte durch leicht andere Silhouette/Farbring und maximal 1–3 kleine Symbole erkennen, worauf er sich einlässt. Kein Bildschirm voll Text. Ein kleines `ELITE`-Label beim Kill ist okay. Endstatistik: Elite-Kills und meistgesehene Affixe.

---

## 5. DREI ECHTE BOSSKÄMPFE MIT PHASEN

Baue die bereits vorhandenen drei Bosse aus, behalte deren Namen, Spawnminuten, HP-Grundwerte, Drop-Logik und Boss-Truhenberechtigung bei. Nichts durch einen generischen identischen Boss ersetzen. Jeder Boss erhält **Phase 1 über 50 % HP** und **Phase 2 ab 50 % HP**; Übergang nur einmal, 0,6 s gut sichtbares Warnzeichen, keine unfairen Soforttreffer. **Bestehender Code-Hinweis:** In `world.gd` wird `e.phase` aktuell bereits für den wechselnden Angriffsschritt benutzt. Verwende ein eigenständiges Feld wie `boss_hp_phase` für den HP-basierten Phasenwechsel und `attack_pattern_step` für den Rhythmus; niemals beides in ein einziges `phase`-Feld zwängen. Beim Pool-Reuse beide Felder zurücksetzen. Der Boss darf in Übergang/Zustandswechseln nicht unsichtbar teleportieren oder Spieler-Inventar/HP modifizieren.

### 5.1 Astral Guardian – Dash & Starfall

- Phase 1: eigener Grundangriff bleibt; zusätzlich alle 5 s **vorher sichtbare, schmale Dash-Telegraph-Linie** 0,8 s, dann geradliniger Dash mit 240 px/s, max. 0,7 s. Richtung nach Telegraph fixieren, währenddessen nicht nachlenken.
- Phase 2: Dash alle 4 s mit 0,9-s-Warnung, dazu alle 7 s **drei kleine Sterneneinschläge** rund um die vorherige Spielerposition, jeder 65-px-Kreis mit 1,0-s-Bodenmarkierung vor Schaden. Sicherer Fluchtkorridor muss bleiben.

### 5.2 Void Queen – Summons & Null Zones

- Phase 1: aktuelle Mite-Summons beibehalten, aber höchstens sechs aktive Kinder dieses Bosses gleichzeitig; dazu zwei langsame Leerenprojektile als klar lesbare Bögen alle 6 s.
- Phase 2: alle 7 s **zwei Null Zones** (je 75 px Radius), 1,0 s Warnung, danach 2,5 s aktiv. Kontakt erzeugt begrenzten, nicht stapelnden Slow für max. 1 s und höchstens alle 0,8 s Schaden. Gleichzeitig höchstens vier solche Zonen. Summons nicht in Zone und Spieler kollidierend spawn-en.

### 5.3 Storm Core – Radial & Safe Gap

- Phase 1: vorhandene radialen Angriffe und Linien; bei radialem Angriff eine **gut erkennbare Lücke** von mindestens 50 Winkelgrad lassen, Angriffe 0,8 s vorher telegraphieren.
- Phase 2: alle 6 s eine größere Radial-Salve mit mindestens 60-Grad-Sicherheitslücke, abwechselnd drei telegraphierte Strahlen mit 1,0 s Vorwarnung. Cap auf Linien und Projektile; keine mathematisch unvermeidbare Überlagerung von Strahlen und Salven.

### 5.4 Allgemeine Boss-Regeln

- Gefahrenzonen haben eine Vorwarnfarbe (gelb/orange), werden beim Treffer kurz rot und verschwinden eindeutig. `reduce_flash` respektieren.
- Boss-Phasen-Signal an HUD, z. B. kleiner Text `Astral Guardian · Phase II`; HP-Bar visuell und lesbar, keine neue riesige UI.
- Keine neuen Bossarten, kein Endlosboss. Boss-Kills zählen weiter für bestehende Achievements und Meta/Run-Stats.
- Boss-Truhen-Bedingung bleibt an **Spawnzeit** des Bosses ab 10:00 gebunden, nie an den Zeitpunkt des Aufhebens. Phase-II-AI darf diese Information nicht löschen.
- Boss-Scaling muss mit bestehenden Minutenskalierungen, `curse`, Instabilitätswerten und Quick Mode zusammen funktionieren.
- Tests für Phase-Transition genau einmal, Warnzeit vor Hit, Grenzfälle, gefährliche Überlappung, keine Boss-Duplikate, keine Verluste der Chest-Evolution.

---

## 6. ELEMENTARSYSTEM / REACTIONS

Das Elementarsystem ist **keine neue Waffengattung** und kein neues Passivslot-System. Ordne bestehenden Waffen/Effekten mit Daten-Tags `fire`, `frost`, `storm`, `toxin`, `void` zu. Viele bestehende Angriffe haben ohnehin `burn`, `slow`, `poison` oder `mark`; bestehende Statuseffekte dürfen nicht doppelt pro Tick berechnet werden.

### 6.1 Ausgangs-Tags (balancierbare Defaults)

- `fire`: `ash_bow`, `sun_beam`, `meteor_rain`; relevante Burn-Mutationen.
- `frost`: `frost_shard`, `moon_blade`; `Crescent Chill`, bestehende Frost-Effekte.
- `storm`: `lightning_call`, `spark_orbit`, `storm_bomb`; `Charged Air`.
- `toxin`: `thorn_halo` und die `Venom Thorns`-Mutation; Poison-Effekte.
- `void`: `soul_well`, `shadow_fan`, `gravity_mine`, `reaper_gaze`.
- `arcane_needle` und `prism_disc` sind vorerst **neutral**, falls keine passende Mutation ein Element ergänzt. Evolutionen/Fusionen erben die Element-Tags ihrer Basen in einer **Set-Union**, nicht als doppelte Listeneinträge. Nur die Tags, die ein Treffer tatsächlich aufträgt, für Reaktionen verwenden; visuell vorhandene, aber nicht getroffene Waffen lösen nichts aus.

### 6.2 Vier konkrete Reaktionen

Ein Gegner merkt pro Element `last_applied_time` und `last_source_weapon`; beim Treffer mit einem **anderen Element innerhalb von 3,0 s** darf eine passende Reaktion ausgelöst werden. Das aktuelle Element selbst zählt nicht zweimal. Elementare Reaktionen haben pro Ziel gemeinsamen **1,5-s-Cooldown** und werden nur auf echten Treffern, nicht pro Frame, entschieden.

| Kombination (Reihenfolge egal) | Reaktion | Effekt |
|---|---|---|
| `frost + storm` | **Arc Freeze** | 35 % des auslösenden Hit-Schadens als elektrischer Zusatzeffekt und 1 kleiner Ketten-Hit auf nahen anderen Gegner (120 px) mit 30 % desselben Basis-Hits |
| `fire + toxin` | **Blightburst** | Explosion 60 px, 45 % des auslösenden Hit-Schadens an bis zu 8 Zielen, mit leichtem Burn-Effekt ohne erneuten Reaction-Trigger |
| `frost + void` | **Void Shatter** | 50 % des auslösenden Hit-Schadens als Bonus auf Primärziel und ein 0,75-s-Slow (auf Bosse max. 0,35 s) |
| `storm + void` | **Rift Conduction** | 25 % des auslösenden Hit-Schadens an bis zu 2 zusätzliche Ziele innerhalb 140 px |

**Schadensregeln:** Triggering Hit ist der *bereits endgültig berechnete Schaden vor Abzug am Gegner*, aber ohne Reaction-Schaden; Reaktionsbonus selbst darf weder kritisch treffen noch die bestehende Damage-Multiplikationspipeline nochmals komplett durchlaufen. Boss-Reaktionen verursachen **50 %** des genannten Bonus-Schadens. Pro Sekunde global höchstens **40 Reaction-Events**, zusätzlich zum lokalen Ziel-Cooldown, um bei 400 Gegnern Lastspitzen zu vermeiden. Priority bei mehreren möglichen Kombis nach fester Tabellenreihenfolge; nur eine pro Treffer. Reaktions-Schaden ist als `proc=true` markiert und kann **keine Reaktion, Mutation, Crit-Reroll, On-Kill-Explosion oder Lifesteal-Kaskade** auslösen. Schadenszuordnung im Endbildschirm konsistent: `Elemental Reactions` als eigene Quelle plus optional auslösende Waffen-ID als Metadatum, aber kein Doppelzählen in den Summen.

UI: kleine dezente Partikel / ein kurzer Reaction-Name an maximal wenigen gleichzeitigen Stellen, Mini-Legende im Build-Preview. Für farblich eingeschränkte Spieler Elementnamen und Symbole, nicht nur Farben. Tests jeder Kombination beider Reihenfolgen, Neutral-Waffe ohne Tag, mehrere Waffen derselben Kategorie, Fusion mit Tag-Union, Boss-Schadensbremse, Event-Caps und nie rekursive Procs.

---

## 7. STERNENKONSTELLATIONEN – PERMANENTER STAR-MAP-TALENTBAUM

Ein **zweiter Fortschrittsbaum**, parallel zum bestehenden 20-Upgrade-Meta-Shop, ohne ihn zu ersetzen. Im Hauptmenü neue Schaltfläche **`Star Map`**, mit eigener scrollbarer, gut bedienbarer UI. Optik: drei kleine, durch Linien verbundene Sternbilder, geometrisch schlicht passend zum Rest. Keine zusätzliche Arena, kein Skilltree innerhalb eines laufenden Runs. Bereits erworbene Knoten wirken **ab dem nächsten Run**.

### 7.1 Währung `Starlight`

Neues dauerhaftes `starlight` (integer), getrennt von `total_gold`.

- Pro Run bei Abschluss **+1 Starlight für den ersten besiegten Boss**, **+1 für den zweiten**, **+1 für den dritten**; weitere Boss-Kills geben im selben Run kein Starlight. Diese Auszahlung erfolgt am Run-Ende basierend auf echten Boss-Kills.
- **+3 Starlight bei Sieg (30:00)**.
- **+1 Starlight**, wenn mindestens 20:00 erreicht wurden.
- **+1 Starlight**, wenn der Run mindestens einmal 75 Instabilität erreicht hat.
- **Maximal 8 Starlight pro Run**, auch bei Debug-Shortcuts, Quick Mode oder mehreren bossartigen Gegnern. Bei Niederlage bleiben verdiente Starlight-Punkte gemäß Kriterien erhalten.
- Genau einmal gutschreiben, selbst bei mehrfachem Result-Aufruf oder Neustart. Reset All Data entfernt Starlight und alle gekauften Star-Map-Knoten. Alte Saves enthalten 0 Starlight und keine gekauften Knoten, **ohne Verlust bisheriger Daten**.

### 7.2 Erwerbsregeln

Drei Pfade mit je **6 Knoten = 18 Knoten gesamt**. Um Knoten Nr. 2...6 zu kaufen, muss jeweils sein direkt vorangehender Knoten **im selben Pfad** gekauft sein; der erste ist frei kaufbar. Preise pro Position **[1, 2, 3, 4, 5, 6] Starlight**, pro Pfad 21, für vollständigen Baum 63. Nie zweimal denselben Knoten kaufen. Keine negative Währung. Sofortiges persistentes Speichern inklusive Fehleranzeige bei fehlgeschlagenem Save; bei Fehlschlag Kauf/Währungsabzug zurückrollen.

### 7.3 Drei vollständig definierte Pfade

**Constellation of Comets (Bewegung / XP / Mobilität):**

1. `Comet Spark` (1) – Start-Laufgeschwindigkeit +1 % (additiv zu Meta, unter bestehendem 500-px/s-Cap).
2. `Gathering Tail` (2) – Magnet-Radius +6 px.
3. `Swift Orbit` (3) – Projektilgeschwindigkeit +3 %.
4. `Astral Insight` (4) – XP-Growth +2 % (kein zweiter Growth-Multiplikator auf XP aus Riss-Überladung).
5. `Rush of Stars` (5) – nach Boss-Kill +2 % Bewegung für 20 s, überschreibt sich bei erneutem Kill nur bis max. 20 s.
6. `Far Traveler` (6) – zusätzliche +6 px Magnet-Radius und +1 % Bewegung.

**Constellation of the Veil (Überleben / defensive Utility):**

1. `Veil Seed` (1) – +3 Max-HP.
2. `Quiet Pulse` (2) – +0,05 HP/s Regeneration.
3. `Guarded Orbit` (3) – −3 % empfangener Schaden von Boss-Projektilen, nie unter Mindestschadenregel.
4. `Second Breath` (4) – Heilung durch Riss-Stabilisierung zusätzlich +4 HP.
5. `Still Heart` (5) – alle 5 Minuten exakt 2 HP wiederherstellen, wenn HP unter 50 % liegt; max. 6-mal in einem normalen Run.
6. `Last Star` (6) – beim ersten Sinken unter 25 % HP einmalig +8 HP heilen, sofern lebendig; kein zweites Auslösen nach erneutem Unterschreiten.

**Constellation of Fractures (Instabilität / Elite-Risiko / Belohnung):**

1. `Rift Sense` (1) – Instabilitätsband und nächste Schwelle im Pausenmenü detailliert sichtbar; Grund-HUD-Wert bleibt für alle Spieler sichtbar.
2. `Tainted Treasure` (2) – +5 % Gold von Elite-Gegnern, wenn Instabilität mindestens 50 beträgt.
3. `Hunter's Star` (3) – +3 % Schaden ausschließlich gegen Elite-Gegner.
4. `Clear Horizon` (4) – beim Stabilisieren eines Rissknotens zusätzlich −3 Instabilität.
5. `Risk Seeker` (5) – beim Überladen eines Rissknotens zusätzlich +5 % von dessen **einmaliger XP-Belohnung**.
6. `Fracture Mastery` (6) – ab Instabilität 75: +3 % Schaden ausschließlich gegen Bosse, keine globale Schadensbuff-Spirale.

Alle konkreten Boni in `run_model.recalculate`, Status-Hooks oder klar definierten Stellen anwenden. Sie müssen mathematisch korrekt mit vorhandenen Meta-Upgrades, Passivitems, Mutationen und Instabilitätswerten zusammenspielen. Nicht mehrere laufende Buffs ungebremst über Tick addieren. `Star Map` zeigt vor Kauf Effekt, Preis, gekauft/gesperrt, Voraussetzung, verfügbares Starlight und **echte** Buttons. Nach Kauf direkt speichern; bei Run-Start Snapshot der gekauften Knoten. Ein Reset muss bis zur Default-Star-Map führen. UI auch bei 1280×720, 1920×1080 und Controller bedienbar.

---

## 8. SEHR DEZENTES TREFFERFEEDBACK (KEIN KRASSER SCREENSHAKE!)

Das bestehende Projekt hat bereits `world.shake`, `screen_shake`, `reduce_flash`, `damage_texts`. Diese Systeme sanft erweitern statt einen neuen schweren Postprocessing-Effekt aufzubauen:

- Normale Spieler-Treffer: **kein Kamerashake**. Kurze dezente Spieler-Silhouetten-Aufhellung maximal **0,07 s**; nicht bildschirmfüllend.
- Starker Boss-Treffer am Spieler: optional Kameraversatz von **maximal 1,5 Pixeln**, maximal **0,07 s**, weich und auf 0 zurück. Großexplosion beim Boss-Tod optional **maximal 2,0 px für 0,10 s**; KEIN Shake bei jedem Projektil/normalen Monster-Kill. Auf keinen Fall bestehende zufällige `±3`-Pixel-Kamera-Jitter unverändert für alle Ereignisse beibehalten.
- Gegner-Hitflash sehr kurz und entsättigt, maximale 0,06 s; im bereits vorhandenen `reduce_flash`-Modus vollständig unterdrücken oder stark abschwächen. Keine weißen Ganzbildblitze.
- Kritische Schadenszahlen erhalten leicht andere Größe/Farbe, z. B. +10 % Schriftgröße; bei vielen Treffern weiterhin Text-Cap 70 beachten und keine zusätzlichen Fonts/Textures pro Hit laden.
- Kleine kontrollierte Treffer-Partikel/Impacts, vorhandenen FX-Cap (180) respektieren. Maximal 1–2 generische kleine Partikel je wichtiger Trefferart, nie pro Beam-Tick alles vollzeichnen.
- Einstellungen `Screen Shake`, `Reduce Flash`, `Damage Numbers` müssen weiter funktionieren. Shake standardmäßig nur dezent, keine Änderung der älteren gespeicherten Präferenzen. Animationseffekte dürfen kein Gegner- oder Hitboxverhalten verändern.

Optisches Ziel: mehr Gewicht und Feedback bei Kämpfen, aber ruhig, lesbar und angenehm für längere 30-Minuten-Runs.

---

## 9. DETAILLIERTER ENDBILDSCHIRM / ECHTE RUN-STATISTIKEN

Erweitere den bestehenden Sieg-/Niederlagebildschirm (`scripts/app.gd -> result()`), ohne Gold/Meta-Finish zweimal zu buchen. Echte Laufzeitdaten zentral bei Kampftreffern und Ereignissen sammeln; **keine erfundenen Werte aus Waffenlevel berechnen**.

**Zusätzliche Daten je Run:**

- Ergebnis, Held, Arena, Quick Mode, Curse, Dauer, Level, Kills, Boss-Kills, Elite-Kills, Gold, Starlight, Anzahl Upgrades/Mutationen/Evolutionen/Fusionen.
- `Total Damage Dealt`, `Damage Taken`, `Total Healing`, `Critical Hits`, `Highest Single Hit`.
- `Total Damage by Weapon`: für jede tatsächlich benutzte Base-/Evolved-/Fusion-Waffe inklusive korrektem Anzeigenamen, verursachtem tatsächlichem Schaden (Overkill nicht als zusätzlicher Schaden zählen oder konsistent dokumentieren), prozentualer Anteil, durchschnittlicher DPS über tatsächliche Run-Dauer; separat `Elemental Reactions`.
- Wenn Basiswaffe evolviert: **Basis- und Evolutionsschaden getrennt zählen**, im UI gruppiert darstellbar, um die Entwicklung nachvollziehen zu können. Mutationen sind Teil der jeweiligen Waffenquelle, nicht künstlich als komplett neue Waffe zählen.
- `Highest 10-Second DPS` (rollierendes oder in Sekundentöpfen aggregiertes Zeitfenster), `Peak Instability`, `Final Instability`, `Rifts Stabilized`, `Rifts Overcharged`, freigeschaltete Erfolge.
- `Most Used Mutation` optional nur, wenn echte Auslösungszähler sinnvoll mitgezählt werden können; sonst weg lassen statt schätzen.

**Mathematische Anforderungen:** Damage nur nach erfolgreichem echten Hit erfassen. Keine doppelte Verbuchung bei AoE, Reaction oder Boss-/Elite-Tod. Keine erfundene sekundengenaue FPS-Statistik. Heilung nur tatsächlich wiederhergestellte HP zählen (nicht überschüssige Heilung). Critical Hits nur echte Krits. `Highest 10-Second DPS` ohne ein Array pro Hit (z. B. 10–11 Sekunden-Buckets als Ringpuffer) implementieren, keine endlos wachsende Liste.

**UI:** Sieges-/Niederlagentitel und Haupt-KPIs oben, darunter scrollbarer Statistikbereich und nach Schaden sortierte Waffenzeilen; neben Schaden Prozente oder kleine Balken, auch ohne neue Artworks verständlich. `Main Menu` und `Try Again` immer erreichbar, besonders mit Controller/1280×720. Neue Starlight-Belohnung deutlich anzeigen und erklären. Bestehendes `best_run_records` und `stats` nicht beschädigen.

---

## 10. BUILD-VORSCHAU IM PAUSENMENÜ

Zusätzlicher Button `Build Details` im existierenden Pausenmenü. **Keine Informationen offenlegen, die die Collection noch absichtlich versteckt.** Die bisherige Regel `evolved_recipes` ist bindend: Evolutionen/Fusionen werden erst nach tatsächlicher Ausführung mit Namen und Rezept angezeigt. Geheimrezepte NICHT durch Level-4-Mutation, Katalysator-Besitz, Star-Map-Kauf oder Build-Detail-View verraten.

In einem scrollbaren Overlay anzeigen:

1. Alle sechs Waffenslots: Name, Basis-/Evolved-/Fusion-Status, Level bzw. Evolved, Attack-Behavior in spielerfreundlichem Text, Mutation und Beschreibung, bei Fusion `Primary` und `Echo 50%`.
2. Alle sechs Passivslots mit Level und **tatsächlich wirksamen** Stats.
3. Runes (max. drei), aktuelle Meta- und Star-Map-Boni und akkumulierte End-Stats: Max-HP, aktuelle HP, Regeneration, Move Speed, Might, Cooldown, Area, Duration, Projectile Speed, Amount, Magnet, Growth, Luck, Crit Chance, Crit Multiplier.
4. `Rift Instability` mit aktuellem Band und aktuell wirkenden Feind-/Loot-Modifikatoren; künftige Schwelle nur wenn `Rift Sense` erworben. Aktive temporäre Boni und Restlaufzeit (wo vorhanden).
5. `Elements & Reactions`: aktuell ausgerüstete Element-Tags und die **generellen** vier Kombinationen dürfen angezeigt werden; das sind keine geheimen Evolutionsrezepte.
6. `Evolution Paths`: bereits ausgeführte/entdeckte Rezepte verständlich samt erfüllten Anforderungen; noch geheime Rezepte nur als „X undiscovered possibilities connected to your equipment“ ohne Name, Basiskombi, Katalysator oder Resultat zu nennen. Die bereits vorhandene Funktion `pause_recipe_text()` gilt als Datenschutz-/Spoiler-Vorbild.
7. Während Pause keine Simulation/Run-Zeit fortschreiben, kein zusätzlicher XP-Roll, keine doppelt ausgewählte Karte.

Biete `Back to Pause` und `Resume` mit tastatur-/gamepadbedienbarer Fokusführung. Die Build-Vorschau darf auch während Boss-Warnungen geöffnet werden. Bei Käufen/Level-Ups wird die Vorschau beim nächsten Öffnen neu aus dem Model berechnet; keine veralteten kopierten Daten.

---

## 11. TECHNISCHE ARCHITEKTUR – KONKRETE INTEGRATION

Folgende Aufteilung ist empfohlen, falls sie zum tatsächlichen Checkout passt:

- `scripts/run_model.gd`: Instabilitätswert, Runtime-Mutation-Dictionary, Mutationsauswahl-Signale/Queue, permanente Star-Map-Snapshot-Boni, Run-Stats, Win/Loss-Verknüpfung. `model.weapons` bleibt gewöhnliche Waffe→Level-Zuordnung; **keine Mutationen als zusätzliche Waffen in die sechs Slots**.
- `scripts/combat.gd`: Mutationsmodifikatoren beim Generieren der Parameter, on-hit/secondary hooks, Procs und Anti-Rekursion, Elemente und Attribution. Wenn gewünscht neuen `scripts/combat_modifiers.gd` und `scripts/element_reactions.gd` als kleine sauber begrenzte Hilfsobjekte.
- `scripts/world.gd`: Elite-Spawn-Director/Affixe/Pooling, Rissknoten-World-Objekte, Boss-Phase/Telegraph/Hazards, Damage-Events, dezentes Hitfeedback, Instability-Spawn-Modifikatoren. Separater `scripts/elite_affixes.gd`/`scripts/boss_patterns.gd` erlaubt, wenn es die Datei klarer macht.
- `scripts/app.gd`: Mutations-Auswahl in bisherige `events`-FIFO-Modalsteuerung integrieren; Rift-Interaction, Build Details, Star Map und erweiterte Resultseite. UI muss `get_tree().paused` korrekt handhaben. Keine internen UI-State-Mischungen wie gleichzeitig `LEVELUP` + `MUTATION`.
- `scripts/save_manager.gd`: additive `starlight`, `constellation_nodes` (eindeutige IDs), neue optional aggregierte Lifetime-Statistiken, robuster Read/Write/Reset. Mutationen sind **run-lokal** und sollen nicht als global freigeschaltet markiert werden, solange dafür kein eigenes System spezifiziert wurde.
- `scripts/data/registry.gd` / neue Ressourcen: 45 Mutationsdefinitionen, sieben Elite-Affix-Datensätze, Star-Map-Knoten, Element-Tags. Alle IDs validieren; fehlende Einträge beim Booten als konkreter Testfehler, nicht als stumme Defaults.
- `docs/`: `FEATURES_PHASE_E.md` für neue Mechaniken/Balance-Tabellen sowie aktualisierte `README.md`, `DESIGN.md`, `BALANCE.md`, `STATUS.md` und `docs/SMOKE_TEST.md`.

**Wichtige Edge Cases:**

- Existing `world.hit(e, damage, values, source, proc, origin)` und die dortigen bereits vorhandenen Burn/Poison/Slow/Mark/Execution-Mechaniken respektieren. Insbesondere `execution_seal` und `reaper_gaze` nicht versehentlich mehrfach verstärken.
- Object Pooling: Beim Reuse aller Feinde, Projektile, Effekte, Drops neue Elite-/Element-/Boss-/Mutation-Zustände vollständig zurücksetzen; `id` und Spawnzeit nicht verwechseln.
- Boss-Truhen werden weiterhin anhand des **Boss-Spawn-Zeitpunkts** berechtigt, nicht anhand des Loot-Collect-Zeitpunkts.
- Die existierenden zwei Fusionen **behalten Vorrang** bei berechtigter Evolution. Vererbte Mutationen allein ändern niemals diese Priorität.
- Die bestehenden Waffen `prism_disc` (distinct-target bounce), `gravity_mine` (armed mine pull/slow), `reaper_gaze` (weakest-target execute) funktionieren unverändert als Grundverhalten, bevor Mutationen greifen.
- Nicht permanent doppelt `recalculate()` pro Frame ausführen. Minutenskalierung, Pacing und Instabilität berechenbar und ableitbar halten.
- Kein neues ungekapseltes `randf()` oder zeitbasierte Rerolls, wenn für Tests die existierende `model.rng` verfügbar ist. Test-Seeds reproduzierbar machen.
- Wenn eine Mutation eine aktive neue Waffe betrifft, keine unendlichen Sekundärtreffer (gemeinsamer Proc-/Budget-Schutz). Globale Limits: ungefähr 430 normale Feinde, 650 Projektile, 300 Pickups, 180 FX und 70 Damage-Texts, sofern aktuelle Projektwerte es so vorgeben.

---

## 12. KONKRETE TESTS UND ABNAHMEKRITERIEN

Erweitere das vorhandene automatisierte Testsystem und führe Tests gegen die **im Cloud-Projekt installierte Godot-4.7.2-Stable-Binärdatei** aus, nicht blind gegen das systemweite `godot` (im bisherigen Cloud-Setup war es eine ältere Version). Vorhandene `tools/check.sh`-Schnittstelle weiterverwenden.

**PFLICHTTESTS, zusätzlich zu allen bestehenden Tests:**

### Mutations-/Evolutionssystem

1. Für jede der 15 Grundwaffen existieren genau drei gültige Mutationsdefinitionen = **45 valide Optionen**; jede Mutation verändert messbar echtes Kampfverhalten (gegebenenfalls definierte Integrationstests).
2. Basiswaffe auf Lv3: keine Mutationsauswahl; Lv3→Lv4: genau eine. Lv4→Lv5→Lv8: keine Wiederholung. Mehrfach-XP-Level-ups verlieren keine Auswahl.
3. Mutation hat keinen Slotverbrauch und verändert nicht die 3er-Normal-Level-Up-Angebote, 6+6-Limits oder die existierenden Reroll/Skip/Banish-Zähler.
4. Für **jede** normale Evolution kann eine Lv4-Mutation mit Level5-Waffe/Level5-Passiv/qualifizierter Truhe korrekt geerbt werden; nicht qualifizierte Truhe evolviert weiterhin nicht.
5. `dusk_storm`: Ash Bow und Frost Shard mutiert → beide Imprints an Fusion, 100 % + 50 %, ein Slot frei, Passiv bleibt. `day_night` analog. Kombinationen ohne Mutation oder nur mit einer Mutation funktionieren ebenfalls.
6. Evolutions-/Fusionserkennung, versteckte Rezeptdaten und `evolved_recipes` bleiben korrekt. Extra Damage der Mutation verletzt nicht die Proc-Caps.

### Instabilität, Elite und Boss

7. Instabilität 0...100, Bandwechsel vor/zurück; Werte gelten genau einmal und skalieren korrekt mit Curse, Wave- und Pacing-Faktoren. Quick Mode entspricht gleicher In-Game-Zeit.
8. Rissknoten zur richtigen Minute; Interaktion nur in Reichweite; vier insgesamt; 90-s-Timeout; jede Wahl einmal, Belohnungen korrekt, modal sicheres Verhalten.
9. Elite nicht vor Minute5; nicht aus Boss-Kindern; Affixe einzigartig; aktive Elite-Caps, Auto-Despawn und Pool-Reset korrekt; Drops und Elite-Kill nur einmal.
10. Alle sieben Affixe wirklich funktional getestet (dmg, AI, Status, Delay, Cooldown, Resource-Cap). Explosionsschaden nur nach Telegraph.
11. Alle drei Bosse: zweite Phase exakt einmal bei <=50 % HP, feste Telegraph-Zeiten und sichere Angriffslücken; vorhandene Rune-/Boss-/Chest-Trigger erhalten.

### Elemente, Star Map, UI, Save

12. Alle vier Elementreaktionen beide Reihenfolgen und Zeitfenster; kein Double-Proc/Reaction-Reentry, 40-Events/s-Cap, Boss-Bonusdämpfung, Korrektheit der Damage Attribution.
13. Star Map: drei Pfade, 18 definierte IDs, Voraussetzungen, Kosten, Wirkung; Summen, Käufe, erneutes Laden, bei Save-Fehler kein verlorener Punkt; 8-Starlight-Cap pro Run; alte Save-Daten erhalten.
14. Volles `Reset All Data` leert neue und alte Daten wie bisher, Bestandsdaten älterer gültiger Saves ohne neue Felder werden migriert statt für kaputt erklärt.
15. Detaillierte Schadenstabellen summieren sich ohne Doppelzählung zum Gesamtschaden, inkl. AoE, evolvierter Waffen und Reaktionen; Healing und High Hit korrekt.
16. Build Details zeigt ehrliche aktuelle Werte und Mutation/Imprint, aber **leakt keine geheime Evolution** vor der tatsächlichen Ausführung.
17. `Screen Shake=false` bewirkt 0 Kameraversatz; mit `true` max. 1,5 px (Boss-Hit) bzw. 2 px (Boss-Kill). `Reduce Flash=true` unterdrückt intensive Blitze. Normale Hits bewegen die Kamera nicht.
18. GUI: 1280×720, 1600×900, 1920×1080, Fenstermodus und eingebettete Godot-Ansicht; keine Regression bei Audio-/Auflösungs-Einstellungen, Fokusführung für Controller.
19. Kompletter beschleunigter **30-Minuten-Run** erfolgreich; reguläre Bosse, Elites, Mutation, Instabilität, finale Resultseite und Währungsabrechnung. Stress-Test mindestens bisheriges Niveau, keine stotternden O(n²)-Proc-Ketten, keine ungeregelten Array-Allokationen, keine Parser-/Engine-Errors.
20. **Alte bestehenden Tests** ebenfalls grün. Wenn Gameplay-Balance Tests durch neue Inhalte sinnvolle neue Erwartungen brauchen, Testfälle nachvollziehbar anpassen; nicht einfach löschen oder deaktivieren.

**Reale manuelle Checks transparent benennen:** Ein Headless-Test beweist weder gleichmäßige reale FPS, noch Controller-Haptik, noch 30 Minuten menschliche Spielbalance. Nicht solche Prüfungen als erfolgt ausgeben, wenn nur Simulationen liefen. Mindestens relevante grafische Smoke Screenshots für Star Map, Mutationsauswahl, Rift-Knoten, Boss-Phase-II-Warnung, Build Details und Endstatistiken erzeugen/prüfen, soweit die Umgebung dies ermöglicht.

---

## 13. INKREMENTELLE ARBEITSPHASEN

**Phase E1 – Fundament & Schema:** Repo/Status analysieren, kurzer Plan, deterministische Datenmodelle/Schnittstellen für Mutation, Instabilität, Element-Tags und Runtime-Stats; Save-Migration und Tests. Bestehende Spielbarkeit nachweisen.

**Phase E2 – Mutationen + Evolutionsintegration:** 45 Mutationen, Lv4-Auswahl, alle 15 Waffen-Vererbungen und beide Fusionen, Build-Anzeige, Tests. **E2 ist erst fertig, wenn Mutationen und Evolutionen tatsächlich gemeinsam funktionieren.**

**Phase E3 – Instabilität, Rift-Knoten, Elites, Bossphasen:** Director, neue Schwierigkeit, Interaktionen, Affixe und konkrete Bossmuster samt Telegraph und Drop-Integration. Tests und Smoke-Checks.

**Phase E4 – Elementreaktionen:** Tags, per-Enemy-Zustand, vier Kombinationen, Damage Attribution, Proc-Schutz, Caps, Tests.

**Phase E5 – Star Map:** Persistente Währung, 18 Knoten, UI, Status-Snapshots, additive Save-Migration, Reset, Tests.

**Phase E6 – Polishing und Datenanzeige:** sehr leichtes Hitfeedback, detaillierter Endbildschirm, Build Details und echte Combatstatistiken, UI-Tests, Performance-/30-Minuten-Tests, Dokumentsynchronisierung.

Nach jeder Phase `STATUS.md` mit **konkreten Dateien, Testzahlen, verbleibenden Problemen und Git-Commit-Hash** fortschreiben. Falls Codex durch Kontext-/Zeitlimits nicht alles auf einmal schafft, abgeschlossene Phasen **wirklich committen**, die nächste Aufgabe und noch offene Fehler in `STATUS.md` festhalten und am nächsten Arbeitspunkt fortsetzen. Kein „alles implementiert“, wenn Tests fehlen oder Teile nur simuliert sind. Vor jeder Änderung der letzten Phase erneut `git status` prüfen.

---

## 14. VERBINDLICHE ABSCHLUSSDEFINITION

Ein Ergebnis zählt nur als fertig, wenn alle neun ausdrücklich gewünschten Systeme **im realen bestehenden Projekt sichtbar, spielbar, integriert und getestet** sind. Es ist nicht genug, `.md`-Pläne, unverknüpfte `.tres` oder Mock-Implementierungen anzulegen.

Am Ende bitte eine kompakte Abschlussantwort mit:

- Implementierte Featuregruppen und den wichtigsten Designregeln (vor allem **Mutation → normale Evolution / Fusion ohne Konflikte**).
- Geänderten Hauptdateien und aktualisierter Dokumentation.
- **Tatsächlich ausgeführten** Godot-4.7.2-Befehlen, Testanzahl PASS/FAIL, ggf. manuellen offenen Checks und tatsächlichen Fehlern.
- Tatsächlichen Git-Commit-Hashes, aktuellem Branch und nachvollziehbarer Angabe, ob ein Remote-Push erfolgreich war. Falls möglich den Push und den sichtbaren GitHub-Stand prüfen.
- 3–5 knappen Schritten, wie das Spiel lokal in Godot getestet wird (Projekt importieren, F5, Mutation auf Lv4, ab 10:00 Evolution mit Truhe, Star Map im Menü).

**Beginne jetzt. Arbeite selbstständig am Code, nicht nur am Text. Keine Rückfrage nach bereits festgelegten Regeln. Die bereits bestehende Spielfunktionalität muss zu jedem Zeitpunkt erhalten bleiben.**
