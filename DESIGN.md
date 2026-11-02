# Architektur und bewusste Entscheidungen

## Schichten

- `scripts/data/*_definition.gd`: acht typisierte Resource-Unterklassen, gemeinsame exportierte Felder über `definition.gd`. `.tres`-Definitionen werden vom Registry-Katalog validiert und niemals zur Laufzeit mutiert.
- `scripts/data/registry.gd`: einmal geladene Kataloge, Abhängigkeitsprüfung und neue, mutable Kopien für Waffenlevel/Evolutionen. Godots Resource-Cache vermeidet doppelte Assets.
- `scripts/run_model.gd`: reine Run-Daten, deterministische Stat-Neuberechnung, XP/Overflow, Inventar, Angebote und Rezepte. Signals für XP, HP, Level, Inventar, Kills, Bosse, Runen, Zeit, Gold und Endzustand.
- `scripts/world.gd`: Spawn-Director, Gegner-KI, Drops, Statusverwaltung, echte Segment-/Kreistreffer, Bossangriffe, Laternen und prozedurale Arena.
- `scripts/combat.gd`: Dispatch nach datengetriebenem Verhalten. Geschoss, Fächer, Orbit, Aura, Blitz, Bumerang, Bombe, Rundumsalve, Beam, Zone und Meteor haben eigene Algorithmen. Evolutionen verändern dieselben echten Algorithmen mit zusätzlichen Prozessoren.
- `scripts/player.gd`: CharacterBody2D mit Floating-Bewegung, Collider, Kamera und I-Frame-Darstellung; Godot-4-`move_and_slide()` ohne Delta-Argument.
- `scripts/app.gd`: tatsächliche Controls für alle Menüseiten, HUD und serialisierte Modal-Queue. Keine leeren Szenen zur künstlichen Erfüllung einer Dateiliste. Drei echte Einstiegsszenen: Menü, Arena, Spieler.
- `scripts/save_manager.gd`: typgeprüfter JSON-Save, Defaults, Korruptionsbackup, atomare Temp-Datei, Shop und eventbasierte Unlocks; pro Run ein Banked-Flag gegen Doppelbuchung.
- `scripts/audio_manager.gd`: originale Synthese von Musik und drei Soundeffekten, getrennte Busse und begrenzte Polyphonie.

## Treffer, Pools und Pause

Alle leichten Entitäten werden als mutable Dictionaries in begrenzten Arrays verwaltet und nach Entfernen vollständig zurückgesetzt wiederverwendet. Das vermeidet hunderte Nodes, CollisionObjects und Signalverbindungen. Nur der Spieler benutzt CharacterBody2D; manuelle Treffer ersetzen Gegner-Physics-Bodies. Collision-Layer Spieler = 1, Mask = 0; Dekor kollidiert bewusst nicht.

Spatial Hash mit 96-px-Zellen wird vor/nach Gegnerbewegung aufgebaut. Projektiltreffer benutzen breite Zellsuche und exakten Abstand zum Bewegungssegment; schnelle Projektile tunneln nicht. Laser benutzen dasselbe Prinzip entlang eines Strahlsegments. Hit-IDs und Spielzeit entprellen Boomerangs/Orbits. Statusdauern und DoT nutzen nur Simulationsdelta. Tote Gegner sind vor Dropverarbeitung entfernt; Kills, Loot und Gold werden einmal gezählt. Proc-Treffer erzeugen keine weiteren Proc-Ketten.

Normale Gegner sind durch Wellenlimit und zusätzlichen Sicherheitscap begrenzt; Boss-/Add-Budget separat begrenzt. Projektile 650, FX 180, Schadenstexte 70. XP wird bei 250 Juwelen werttreu zusammengefasst; alle Pickups zusammen maximal 300. Bei vollem Pool werden äquivalente Pickups verdichtet, auch mehrere Truhen bleiben als Reward-Anzahl erhalten. XP wird niemals offscreen gelöscht.

RUNNING, LEVELUP, CHEST, RUNE, PAUSED, VICTORY und DEFEAT koordinieren die Welt. `SceneTree.paused` stoppt Welt/Spieler/Kampf; App-UI und Audio laufen im Always-Modus. Ereignisse werden FIFO abgearbeitet, nach einer Wahl bleibt der nächste Event erhalten. Kurzlebiger TRANSITION-Zustand verhindert Doppelauswahl.

## Daten und Darstellung

Die offene Arena ist ein seedunabhängiges, koordinatenstabiles Wiederholungsmuster ohne harte Grenzen. Dekor ist kosmetisch, damit Schwärme nicht hängenbleiben. Gegner sind farbige, verschiedene Polygonformen mit Schatten und Zustandsfarben; Bosse haben HP-Leisten und telegraphierte Angriffe. Helden unterscheiden sich in Farbe/Details, Werten und Startwaffe. Menüs scrollen bei hoher UI-Skalierung und folgen Controller-Fokus.

Vereinfachungen gegenüber einer aufwendigen Art-Produktion: geometrische Silhouetten statt Sprite-Sheets, einfache Highlight-Kreise statt Partikelwolken, ein kurzer synthetischer Ambient-Loop, Text-/Formicons statt gemalter Inventaricons. Die Truhe zeigt ihre reale Belohnung in einem bestätigbaren Overlay mit kurzer Überblendung; die Bestätigung ist sofort verfügbar und überspringt die Animation. Waffenverhalten liegt in getrennten Methoden einer gemeinsamen Combat-Klasse statt je einem separaten Node-Skript. Diese Entscheidungen ändern die Pflicht-Kampfmechaniken nicht.

## Validierung und Grenzen

Headless-Simulation misst CPU-Simulationszeit, **keine gerenderten FPS**. Kein Nachweis von 60 FPS auf durchschnittlicher Zielhardware. Grafischer Smoke-Test nutzt Mesa llvmpipe auf einem virtuellen Xorg-Dummy-Display. Hardwarecontroller, hörbare Audiobalance und ein vollständiger, von einem Menschen gespielter 30-Minuten-Balancecheck sind weiterhin manuelle Aufgaben. Native Windows/Linux-Exportpakete sind nicht erzeugt; das Projekt ist direkt im Editor startbar und verwendet keine plattformspezifischen Spiel-APIs.
