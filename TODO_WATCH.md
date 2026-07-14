# Watch-Erweiterung (Phase 9) – Spezifikation & TODO für Claude Code

> **Anweisung an Claude Code:** Dieses Dokument ergänzt `TODO.md` und detailliert Phase 9
> (Apple Watch). Beginne erst, wenn Phase 1–8 abgeschlossen sind (MVP baut, Tests grün).
> Lies zuerst „Kontext & Entscheidungen" vollständig. Arbeite die Unterphasen **strikt in
> Reihenfolge** ab. Nach jeder Unterphase: Projekt baut (iOS + watchOS), Tests grün,
> Commit mit `feat(phase9.N): <beschreibung>`. Bei Unklarheiten: nachfragen statt raten.

---

## 1. Kontext & Entscheidungen (nicht neu diskutieren)

### Ziel
Drei Watch-Komplikationen mit dazugehöriger Watch-App:
1. **Gewichts-Tracking** – Gewichtseingabe per Digital Crown, inkl. Kreatin-Flag
2. **Schnellauswahl** – Logging von Gerichten/Lebensmitteln in nutzerdefinierter Reihenfolge
3. **Kalorien-Ring** – Tagesfortschritt als Ring mit Zahl in der Mitte

Design-Leitlinie überall: **dunkel, modern, minimalistisch** (siehe Abschnitt 7).

### Technologie-Entscheidungen

| Bereich | Entscheidung | Begründung |
|---|---|---|
| Minimum watchOS | **watchOS 10.0** | WidgetKit-Komplikationen, `.sensoryFeedback`, moderne Navigations-APIs. Passt zur iOS-17-Basis. |
| Komplikationen | **WidgetKit** (`accessoryCircular`, `accessoryCorner`, `accessoryInline`, `accessoryRectangular`) | ClockKit ist deprecated – **nicht verwenden**. |
| Targets | Neues watchOS-App-Target `KalorienTrackerWatch` + Widget-Extension `KalorienTrackerWatchWidgets` | Komplikationen leben in der Widget-Extension, UI in der Watch-App. |
| Code-Sharing | `CalorieCore/Domain` wird im watchOS-Target wiederverwendet (pure Swift, target-unabhängig – Architektur war dafür vorbereitet) | Entities/UseCases nicht duplizieren. |
| Persistenz Watch | **Leichter lokaler Cache** (kleine SwiftData-Instanz nur für Offline-Queue + Snapshot, App Group **innerhalb watchOS** zwischen App und Widget-Extension) | Die Watch ist kein zweiter Full-Store. iPhone bleibt Source of Truth. |
| Sync | **WatchConnectivity (`WCSession`)**. `updateApplicationContext` für Zustand iPhone→Watch, `transferUserInfo` für Events Watch→iPhone (puffert automatisch offline) | Robust, kein Server nötig. CloudKit bleibt Post-Phase-9. |
| Konfliktregel | iPhone = Source of Truth. Watch-Events sind idempotent (UUID pro Event), Last-Write-Wins pro Eintrag | Einfach, nachvollziehbar, keine Merge-Logik. |
| Deep Links | `widgetURL` mit URL-Scheme `kalorientracker://watch/weight`, `.../quicklog`, `.../dashboard` | Jede Komplikation öffnet direkt ihren Screen. |
| Zahlenformat | Deutsche Lokalisierung: Dezimal-Komma („81,4", „1,1K") | Konsistent mit App. |
| Haptik | `.sensoryFeedback` (watchOS 10) bzw. `WKInterfaceDevice.play(_:)` als Fallback | Natives Feedback, kein Custom-Audio. |

### Bewusste Scope-Änderungen (bereits entschieden)
1. **Gewicht wird offizieller Teil des Datenmodells.** In `TODO.md` stand Gewicht auf der
   Ausschlussliste – dieser Eintrag wird gestrichen. Die Ausschlussliste in `TODO.md`
   entsprechend aktualisieren (Kommentar: „→ siehe TODO_WATCH.md").
2. **Gerichte (MealTemplates) werden Voraussetzung.** Die Schnellauswahl braucht
   benannte, zusammengesetzte Gerichte mit hinterlegten Nährwerten. Diese werden auf dem
   iPhone verwaltet (Phase 9.2), nicht auf der Watch.
3. **Interaktions-Regel Schnellauswahl:** Kurzer Tap zeigt nur Details (kcal/Makros),
   **Long-Press (0,6 s) loggt**. Das ist die Fehleingabe-Sicherung aus dem Briefing –
   bewusst so herum, damit „ansehen" niemals versehentlich „loggen" auslöst.
4. **Gewichts-Komplikation zeigt bevorzugt „XX,X"** (aktuelles Gewicht als Zahl).
   Nur wenn noch kein Gewicht existiert: Waagen-Symbol (SF Symbol `scalemass`) als Fallback.

### Explizit NICHT bauen (Scope-Schutz Phase 9)
Kein HealthKit-Export des Gewichts (später), keine Suche/kein Barcode auf der Watch,
kein Standalone-Betrieb ohne gekoppeltes iPhone (initialer Sync nötig), kein Wasser-Tracking,
kein CloudKit, keine Watch-Einstellungen (alles wird auf dem iPhone konfiguriert und synchronisiert).

---

## 2. Datenmodell-Erweiterungen (CalorieCore/Domain + Data)

### Neue Entities (Domain, pure Swift)
```
WeightEntry
├── id: UUID
├── date: Date                 // Zeitpunkt der Messung
├── weightKg: Decimal          // 0,1-kg-Auflösung
└── creatine: Bool             // Kreatin-Flag zum Zeitpunkt der Messung

MealTemplate ("Gericht")
├── id: UUID
├── name: String
├── items: [MealTemplateItem]  // FoodRef + Menge
└── computed: kcal / protein / carbs / fat (Summe der Items)

QuickList (genau eine pro Nutzer)
└── entries: [QuickListEntry]  // geordnet via sortIndex

QuickListEntry (enum-artig)
├── .meal(MealTemplate.ID)
├── .food(Food.ID, defaultAmount)
└── .folder(name: String, items: [QuickListEntry])   // max. 1 Ebene tief
```

### Neue Protokolle (Domain/Repositories)
- `WeightRepository` – save, latest, history(range)
- `MealTemplateRepository` – CRUD
- `QuickListRepository` – load, saveOrder

### Neue UseCases
- `LogWeightUseCase` (nutzt letztes Kreatin-Flag als Default für neuen Eintrag)
- `GetLatestWeightUseCase`
- `LogQuickEntryUseCase` (loggt Gericht oder Lebensmittel als DiaryEntry(s), idempotent via Event-UUID)
- `GetQuickListUseCase`

### Data-Layer (iPhone)
- SwiftData-Modelle `SDWeightEntry`, `SDMealTemplate`, `SDQuickListEntry` –
  **CloudKit-kompatibel** wie gehabt (keine `.unique`-Attribute, optionale Relationships, Defaults).
- Repositories implementieren, mit In-Memory-SwiftData testen.

---

## 3. Sync-Architektur (WatchConnectivity)

```
iPhone                                   Watch
──────                                   ─────
PhoneSyncService                         WatchSyncService
  │  updateApplicationContext              │
  │  { dayTotals, goal, latestWeight,      │  → Snapshot in lokalen Cache,
  │    creatineFlag, quickList (inkl.      │    WidgetCenter.reloadAllTimelines()
  │    Reihenfolge), settings }            │
  │                                        │
  │  ◄── transferUserInfo ─────────────────│  Events:
  │      { type: logQuick | logWeight,     │  - werden lokal gequeued (offline-fähig)
  │        eventId: UUID, payload }        │  - optimistic UI auf der Watch
  │                                        │
  └─ Event anwenden (idempotent via        │
     eventId), danach neuen Context pushen │
```

Regeln:
- Payload versionieren (`schemaVersion: Int`), unbekannte Versionen ignorieren + loggen.
- Watch zeigt nach eigenem Event sofort den optimistischen Zustand; der nächste
  ApplicationContext vom iPhone ist autoritativ.
- Nach jedem verarbeiteten Event und um Mitternacht: Komplikations-Timelines neu laden.
  Reload sparsam einsetzen (Komplikations-Budget).

---

## 4. Feature A – Gewichts-Tracking (Komplikation + Screen)

### Komplikation
- Families: `accessoryCircular` (primär), `accessoryInline`, `accessoryCorner`.
- Anzeige: **„81,4"** (aktuelles Gewicht, eine Nachkommastelle, ohne „kg" im Circular –
  Platz ist knapp; Inline darf „81,4 kg" zeigen). Fallback ohne Daten: SF Symbol `scalemass`.
- `widgetURL: kalorientracker://watch/weight`

### Screen „Gewichtseingabe" (Watch-App)
- Öffnet mit dem **letzten Gewicht** als Startwert, groß und zentriert (SF Rounded, Bold).
- **Digital Crown:** ±0,1 kg pro Raste (`.digitalCrownRotation` mit haptischen Detents),
  Wertänderung animiert (Ziffern-Rolling via `.contentTransition(.numericText())`).
- **Kreatin-Toggle** direkt unter der Zahl: kleiner Pill-Toggle „Kreatin", Zustand =
  letzte Stellung (kommt aus `latestWeight.creatine`). Wird pro Eintrag mitgespeichert,
  damit historisch nachvollziehbar ist, ob damals Kreatin genommen wurde.
- **Speichern:** ein großer Button. Bei Erfolg: Haptik `.success` + kurze
  Checkmark-Animation, Screen schließt sich.
- Sync: Event `logWeight` → iPhone. iPhone erhält den Eintrag in `WeightRepository`.
- iPhone-Gegenstück (minimal): Gewichtsliste unter Einstellungen/Profil
  (Datum, Gewicht, Kreatin-Badge), neueste zuerst. Trend-Chart ist **optional 9.7**,
  nicht Pflicht.

---

## 5. Feature B – Schnellauswahl (Komplikation + Screen)

### Komplikation
- Families: `accessoryCircular` (SF Symbol `bolt.fill` o. ä. aus DesignSystem), `accessoryCorner`.
- `widgetURL: kalorientracker://watch/quicklog`

### Screen „Schnellauswahl" (Watch-App)
- Vertikale Liste **exakt in der auf dem iPhone konfigurierten Reihenfolge**:
  oben die Top-Einträge (typisch: Gerichte), darunter Ordner (aufklappbar, eine Ebene).
- Zeile: Name + kcal, Gerichte mit dezentem Icon unterscheidbar von Einzel-Lebensmitteln.
- **Kurzer Tap:** Detail-Sheet (kcal/Makros, bei Gericht die Bestandteile). Loggt nichts.
- **Long-Press 0,6 s = Loggen:** Während des Haltens füllt sich ein Fortschrittsring um
  die Zeile (optisches Feedback). Bei Abschluss: Haptik `.success` + Checkmark-Overlay.
  Loslassen vor Ablauf bricht ab (Haptik-freies Zurücksetzen).
- **Undo:** Nach dem Loggen 5 s ein dezenter Toast „Geloggt · Rückgängig".
  Undo sendet ein `revertQuickLog`-Event mit derselben Event-UUID.

### iPhone: „Schnellauswahl bearbeiten"
- Eigener Screen (Einstellungen oder Tab „Mehr"):
  - **Drag & Drop-Sortierung** via `List` + `.onMove` (EditMode dauerhaft aktiv auf
    diesem Screen – kein verstecktes „Bearbeiten"-Menü).
  - Einträge hinzufügen: aus Gerichten und aus zuletzt/häufig geloggten Lebensmitteln.
  - Ordner anlegen/umbenennen/löschen, Einträge per Drag in/aus Ordnern verschieben
    (max. eine Ordner-Ebene).
- **Gerichte-Verwaltung** (Voraussetzung, eigener Screen): Gericht anlegen mit Name +
  Zusammenstellung aus mehreren Lebensmitteln (Suche/Barcode/Manuell wiederverwenden),
  Nährwerte werden automatisch summiert und angezeigt. Bearbeiten/Löschen.
- Jede Änderung pusht sofort einen neuen ApplicationContext zur Watch.

---

## 6. Feature C – Kalorien-Ring (Komplikation)

- Family: `accessoryCircular` (primär), zusätzlich `accessoryCorner` mit Gauge.
- **Ring:** `Gauge` mit Fortschritt = gegessen / Tagesziel. Monochrom bzw. eine
  Akzentfarbe aus dem DesignSystem; bei Zielüberschreitung wechselt nur die Ringfarbe
  dezent (kein Blinken, keine Warnsymbole).
- **Zahl in der Mitte**, per Einstellung (iPhone, synchronisiert):
  - Modus „Übrig" (Default) oder „Gegessen".
  - Format: unter 1000 → exakt („850"), ab 1000 → gerundet mit Suffix („1,1K").
    Deutsche Formatierung (Komma). Negative Restkalorien: „−120".
- `widgetURL: kalorientracker://watch/dashboard` → kleines Watch-Dashboard
  (Tageswerte kcal + 3 Makro-Balken, Button zur Schnellauswahl).
- Timeline: Reload nach jedem Sync-Event + Eintrag um Mitternacht (Tagesreset).

---

## 7. Design-Richtlinien Watch (verbindlich)

- **Schwarz als Grundfläche** (OLED), keine Karten-auf-Karten-Verschachtelung.
- Eine Akzentfarbe aus `DesignSystem` – identisch zur iPhone-App.
- Zahlen in **SF Rounded**, groß und dominant; Labels klein, sekundäre Textfarbe.
- Keine Rahmen, keine Schatten; Trennung nur über Abstand und Typo-Hierarchie.
- Animationen kurz (< 0,3 s), `.contentTransition(.numericText())` für Zahlenwechsel.
- Haptik nur bei Bestätigungen (Loggen, Speichern), nie beim Scrollen/Navigieren.
- Alle Strings in den bestehenden String Catalog (Deutsch als Basis).

---

## 8. Phasenplan

### Phase 9.1 – Targets & Grundgerüst
- [x] watchOS-App-Target `FoodReflectWatch` (watchOS 10.0) anlegen
- [x] Widget-Extension `FoodReflectWatchWidgets` anlegen
- [x] App Group **innerhalb watchOS** (App ↔ Widget-Extension) konfigurieren (`group.com.bjoernnnn.foodreflect.watch`)
- [x] `CalorieCore/Domain` im watchOS-Target einbinden (Package: `.watchOS(.v10)` ergänzt, baut ohne Code-Änderungen)
- [x] URL-Scheme `foodreflect://` + Routing-Stub (`WatchRoute`) in der Watch-App
- [x] Platzhalter-Komplikationen (alle drei, statischer Inhalt) mit Deep Links
> Namensanpassung an aktuelles Projekt: `KalorienTracker*` → `FoodReflect*`, Scheme `kalorientracker://` → `foodreflect://`.
> Verifiziert per Simulator-Build (Apple Watch Series 11, watchOS 26.5) + unveränderter iOS-Build. End-to-End auf echter Hardware steht aus (Signing/Pairing lokal).

**Definition of Done:** Beide Targets bauen, Platzhalter-Komplikationen erscheinen im
Zifferblatt-Editor, Deep Links öffnen die richtigen (leeren) Screens.

### Phase 9.2 – Datenmodell & iPhone-Features
- [x] Entities `WeightEntry`, `MealTemplate`, `QuickListEntry` in Domain
- [x] Repository-Protokolle + UseCases (siehe Abschnitt 2), Unit-Tests
- [x] SwiftData-Modelle + Repository-Implementierungen (CloudKit-kompatibel), Tests mit In-Memory-Store
- [x] iPhone: Gerichte-Verwaltung (CRUD, Nährwert-Summierung)
- [x] iPhone: „Schnellauswahl bearbeiten" mit Drag & Drop, Ordnern, Hinzufügen-Flow
- [x] iPhone: Gewichtsliste inkl. Kreatin-Erfassung (Toggle im Sheet) + Kreatin-Badge
- [x] `TODO.md`-Ausschlussliste aktualisieren (Gewicht raus, Verweis auf dieses Dokument)

**Definition of Done:** Gerichte anlegbar, Schnellauswahl frei sortierbar (Reihenfolge
persistiert), alles ohne Watch nutzbar und getestet.

### Phase 9.3 – Sync-Schicht
- [x] `PhoneSyncService` + `WatchSyncService` (WCSession, ApplicationContext + UserInfo-Queue) – Struktur steht, kompiliert iOS + watchOS; **Zustellung nur mit gekoppelter Hardware verifizierbar**
- [x] Payload-Schema mit `schemaVersion`, Codable-DTOs, Mapping-Tests (`SyncCoder`, Versions-Guard, Round-Trip)
- [x] Idempotenz via Event-UUID (`EventDeduplicator` + Doppel-Delivery-Test)
- [~] Watch-Cache (Snapshot + Offline-Event-Queue) in der App Group – Protokolle (`SnapshotStore`, `ProcessedEventStore`) + In-Memory-Default vorhanden; konkrete App-Group-Persistenz kommt mit der Watch-UI (9.4+). Offline-Event-Queue übernimmt WCSession (`transferUserInfo`).
> Neues Modul `Sync` (CalorieCore, iOS + watchOS), 16 Unit-Tests grün. WCSession-Glue in `#if os(...)`-Dateien, damit beide Plattformen bauen.

**Definition of Done:** Änderung am iPhone erscheint auf der Watch; Watch-Event offline
erzeugt → landet nach Reconnect genau einmal im iPhone-Tagebuch.

### Phase 9.4 – Watch: Gewichtseingabe
- [ ] Screen gemäß Abschnitt 4 (Crown-Eingabe, Kreatin-Toggle, Speichern, Haptik)
- [ ] `logWeight`-Event + optimistisches Update des lokalen Snapshots
- [ ] Leerzustand (noch kein Gewicht): Startwert 80,0, Hinweistext eine Zeile

**Definition of Done:** Gewicht in < 5 s erfassbar (Komplikation → Crown → Speichern),
Eintrag inkl. Kreatin-Flag auf dem iPhone sichtbar.

### Phase 9.5 – Watch: Schnellauswahl
- [ ] Liste in synchronisierter Reihenfolge inkl. Ordner
- [ ] Tap = Details, Long-Press mit Fortschrittsring = Loggen, Haptik + Checkmark
- [ ] Undo-Toast mit `revertQuickLog`
- [ ] Leerzustand: Hinweis „Schnellauswahl auf dem iPhone einrichten"

**Definition of Done:** Gericht in < 3 s loggbar, kein Log ohne vollendeten Long-Press,
Undo funktioniert, Tageswerte auf iPhone + Watch konsistent.

### Phase 9.6 – Komplikationen final
- [ ] Gewicht: „XX,X"-Anzeige (Circular/Inline/Corner), Symbol-Fallback
- [ ] Schnellauswahl: Icon-Komplikation mit Deep Link
- [ ] Kalorien-Ring: Gauge + Modus Übrig/Gegessen, „1,1K"-Formatierung (FormatStyle + Tests)
- [ ] Timeline-Reloads: nach Sync-Events + Mitternachts-Eintrag
- [ ] Snapshot-/Preview-Varianten für die Zifferblatt-Galerie

**Definition of Done:** Alle drei Komplikationen zeigen Live-Daten, aktualisieren sich
nach dem Loggen zeitnah, Mitternachts-Reset funktioniert.

### Phase 9.7 – Polish & Tests
- [ ] Haptik-/Animations-Feinschliff gemäß Abschnitt 7
- [ ] Fehlerzustände: iPhone nicht erreichbar (Queue-Hinweis, kein Blocker)
- [ ] Unit-Tests: Formatierer („1,1K", „81,4"), Sync-Idempotenz, QuickList-Sortierung
- [ ] Optional: Gewichts-Trend-Chart auf dem iPhone (Swift Charts, Wochenmittel)

**Definition of Done:** Alle Tests grün, App-Review-tauglicher Zustand beider Targets.

---

## 9. Risiken & Gegenmaßnahmen

| Risiko | Gegenmaßnahme |
|---|---|
| WatchConnectivity-Latenz fühlt sich träge an | Optimistic UI auf der Watch, ApplicationContext nur als Korrektur |
| Komplikations-Update-Budget erschöpft | Reload nur bei echten Datenänderungen + 1× Mitternacht, kein Polling |
| Versehentliche Logs trotz Long-Press | Ring-Feedback erst ab 0,15 s, Abbruch ohne Haptik, Undo-Toast als Netz |
| Doppelte Events bei Reconnect | Event-UUID + Idempotenz-Check im iPhone-Repository (getestet) |
| Scope-Kriechen (Watch-Suche, HealthKit …) | Ausschlussliste in Abschnitt 1 ist verbindlich |
