# FoodReflect – Erweiterungsplan: Lebensmittel-Gruppen & Watch-App

> Ergänzt das bestehende `todo.md` (Rename, Ring, Dashboard, Gewichts-Tab, Unterseiten).
> Dieses Dokument plant zwei neue Feature-Bereiche und ein Bündel Design-/Funktions-Verbesserungen.
> **Abhängigkeitsregel bleibt heilig:** `Features → Domain + DesignSystem`. Neue Targets erben dieselben Grenzen.
> Reihenfolge: erst Datenmodell-Erweiterung (Block A), dann Gruppen (Block B), dann Watch (Block C).

---

## Repo-Check: relevante Befunde für diese Erweiterung

- `DiaryEntry`/`SDDiaryEntry` haben **kein Mahlzeiten-Feld** (`consumedAt` ist nur ein Zeitstempel).
  Für „Frühstück/Mittag/Abend/Snack" braucht es ein neues, optionales Feld – CloudKit-konform mit Default.
- Logging läuft über `LogFoodUseCase` (ein `Food` + Menge → denormalisierter Snapshot). Gruppen = mehrere
  dieser Snapshots in einem Rutsch. Es gibt bereits `useCount`/`lastUsedAt` auf `Food` (Basis für „häufig genutzt").
- Persistenz-Schema wird zentral in `ModelContainerFactory.schema` registriert (`SDFood, SDDiaryEntry, SDGoals`).
  Jede neue `@Model`-Klasse muss dort ergänzt werden (App-Group- **und** In-Memory-Container).
- **App Groups spannen nicht über iOS ↔ watchOS.** Der aktuelle Store liegt im iOS-App-Group-Container.
  Die Watch kann diesen Store **nicht** direkt lesen/schreiben. Watch-Sync braucht **WatchConnectivity**
  (schnell, direkt) und/oder **CloudKit** (die Modelle sind bereits CloudKit-ready). → siehe Block C.
- `WidgetKit` wird bereits genutzt (`accessoryCircular`/`accessoryRectangular`). Watch-Komplikationen sind
  ebenfalls WidgetKit – der bestehende `ProgressRing`/DesignSystem-Code ist wiederverwendbar.

---

# BLOCK A – Datenmodell-Erweiterungen (Fundament für B & C)

Muss zuerst kommen, damit Gruppen und Watch auf denselben Feldern aufsetzen.

- [ ] **Mahlzeitentyp** einführen: `enum MealType: String, Codable, Sendable, CaseIterable { case breakfast, lunch, dinner, snack }`
      in `Domain/Entities/`.
- [ ] `DiaryEntry` + `SDDiaryEntry` um `mealType: MealType` (Default `.snack` oder aus Uhrzeit abgeleitet) erweitern.
      Migration ist unkritisch (SwiftData vergibt Default für Altdaten).
- [ ] `LogFoodUseCase` um Parameter `mealType` erweitern (Default aus `consumedAt` ableiten: <11 Uhr Frühstück,
      <15 Mittag, <21 Abend, sonst Snack – als kleine Hilfsfunktion, überschreibbar).
- [ ] `WeightEntry` (aus `todo.md` Block Gewicht) um **`withCreatine: Bool`** erweitern (Default `false`).
      Dieses Feld trägt die Kreatin-Info und ist die Grundlage für die Watch-Auswertung.
- [ ] Alle neuen `@Model`-Typen in `ModelContainerFactory.schema` registrieren.
- [ ] Tests: Mapper-Roundtrip (`DiaryEntryMapper`, neuer `WeightEntryMapper`) inkl. neuer Felder.
- [ ] Commit `feat(dataA): mealType + withCreatine im Datenmodell`.

---

# BLOCK B – Lebensmittel-Gruppen / Mahlzeiten-Vorlagen

Ziel: wiederkehrende Mahlzeiten mit einem Tipp erfassen (z. B. „Standard-Frühstück" = Haferflocken + Milch + Banane).
Zwei sich ergänzende Konzepte: **(1) Mahlzeiten-Zuordnung** einzelner Einträge und **(2) speicherbare Gruppen-Vorlagen**.

## B1 – Mahlzeiten-Abschnitte im Dashboard/Log

- [ ] Log-Sheet: beim Erfassen `MealType` wählbar (Segmented Control, vorbelegt aus Uhrzeit).
- [ ] Dashboard „Heutige Einträge" nach `MealType` gruppieren (Abschnitte Frühstück/Mittag/Abend/Snack),
      je Abschnitt kleine kcal-Summe rechts. Nutzt vorhandenen `todayEntries`-Fetch, nur Gruppierung im ViewModel.
- [ ] Design: Abschnittskopf mit Icon je Mahlzeit (SF Symbols: `sunrise`, `sun.max`, `sunset`, `moon`),
      farblich dezent an `ColorToken.accent` angelehnt.

## B2 – Speicherbare Gruppen-Vorlagen (der eigentliche „Standard-Frühstück"-Wunsch)

**Domain:**

- [ ] Entity `MealTemplate`: `id`, `name`, `mealType: MealType?`, `items: [MealTemplateItem]`.
- [ ] `MealTemplateItem`: `foodID: UUID`, `foodName` (denormalisiert für Anzeige), `amountGrams`, Nährwerte-Snapshot
      (damit die Vorlage auch bei Katalog-Änderungen stabil bleibt – gleiche Philosophie wie `DiaryEntry`).
- [ ] Protokoll `MealTemplateRepository`: `all()`, `save(_:)`, `delete(id:)`.
- [ ] UseCase `LogMealTemplateUseCase`: expandiert eine Vorlage in N `DiaryEntry`-Snapshots (ruft `LogFoodUseCase`
      je Item bzw. übernimmt die gespeicherten Snapshots), setzt `mealType`, `consumedAt = now`.

**Data:**

- [ ] `SDMealTemplate` + `SDMealTemplateItem` (`@Model`, Defaults, kein unique, Relationship optional → CloudKit-ready).
- [ ] `SwiftDataMealTemplateRepository` (`@ModelActor`), Mapper, im Schema registrieren.

**Feature (`FeatureMeals` oder in `FeatureLog` integriert):**

- [ ] Vorlage **erstellen**: aus aktuellen Tageseinträgen einer Mahlzeit („Diese Mahlzeit als Vorlage speichern")
      **oder** frei zusammenstellen aus dem Katalog.
- [ ] Vorlage **anwenden**: im Log-Sheet Reiter „Vorlagen" → Tipp loggt die ganze Gruppe (mit `mealType`).
- [ ] Vorlagen **verwalten**: Liste, umbenennen, löschen, Items editieren.
- [ ] „Zuletzt/Häufig": zusätzlich Schnellzugriff auf oft genutzte Einzel-Foods (nutzt vorhandenes `useCount`).

**Verdrahtung & Tests:**

- [ ] `MealTemplateRepository` im `AppContainer` erzeugen, per Closure/Init an die Log-/Meals-Views reichen.
- [ ] `project.yml`: ggf. neues Target `FeatureMeals` + Dependency; `xcodegen generate`.
- [ ] Tests: `LogMealTemplateUseCaseTests` (expandiert korrekt, Snapshots stabil), Repo-Roundtrip.
- [ ] Commit `feat(B): Mahlzeiten-Vorlagen & Gruppierung`.

---

# BLOCK C – watchOS-App mit Gewichts-Komplikation

Fokus: **Gewicht in Sekunden erfassen** direkt von der Komplikation, plus Kreatin-Merker.
Die Watch-App ist bewusst minimal – kein voller Tracker, sondern der schnellste Weg zu einer Gewichtsmessung.

## C0 – Target & Sync-Fundament (zuerst)

- [ ] Neues Target `FoodReflectWatch` (watchOS App, SwiftUI) in `project.yml`; Deployment watchOS 10+.
- [ ] `FoodReflectWatch Widget`-Extension-Target für die Komplikation (WidgetKit, accessory families).
- [ ] Watch-Targets hängen **nur** an `Domain` + `DesignSystem` (Abhängigkeitsregel; `Data` bleibt iOS-seitig,
      da SwiftData-Store nicht geteilt wird → siehe Sync).
- [ ] **Sync-Entscheidung dokumentieren.** Empfehlung:
  - **WatchConnectivity** als Primärpfad für die eine Aktion „neue Gewichtsmessung": Watch sendet
    `{weightKg, recordedAt, withCreatine}` per `transferUserInfo` (queued, auch offline) an die iPhone-App;
    iPhone schreibt via `WeightRepository` in den echten Store. Für den Preselect („letztes Gewicht") sendet
    das iPhone `applicationContext` mit letztem Gewicht + letztem Kreatin-Status an die Watch.
  - **CloudKit** optional später als Zweitpfad (Modelle sind vorbereitet), nicht MVP der Watch.
- [ ] Kleiner `WeightSyncService` auf beiden Seiten (Domain-nah, protokollbasiert), damit testbar ohne echte Hardware.

## C1 – Komplikation (der Einstiegspunkt)

- [ ] Komplikations-Widget in `FoodReflectWatch Widget`: unterstützte Familien `accessoryCircular`,
      `accessoryCorner`, `accessoryInline`.
- [ ] Inhalt: aktuelles/letztes Gewicht + kleines Waagen-Icon (`scalemass`); Marken-Türkis (`ColorToken.accent`).
- [ ] **Tap → direkt zur Gewichtserfassung:** `widgetURL(URL("foodreflect://weight/new"))`; die Watch-App
      parst den Deep-Link und öffnet **sofort** den Eingabe-Screen (kein Zwischenmenü).
- [ ] Timeline: aktualisiert sich nach jeder Messung (letztes Gewicht anzeigen); Reload nach Sync anstoßen.

## C2 – Gewichts-Eingabe per Digital Crown

- [ ] `WeightEntryWatchView`:
  - Große zentrierte Gewichtszahl; **Digital Crown** ändert den Wert
    (`.digitalCrownRotation($weightKg, from: 30, through: 250, by: 0.1, sensitivity: .medium, isContinuous: false)`).
  - **Vorauswahl = letztes Gewicht** (aus `applicationContext`/lokalem Cache); beim ersten Mal sinnvoller Default.
  - Haptisches Tick-Feedback bei Schrittänderung (`WKInterfaceDevice.current().play(.click)` bzw. `.sensoryFeedback`).
  - Bestätigen-Button („Speichern") → sendet Messung per `WeightSyncService`, spielt Erfolgs-Haptik, schließt.
- [ ] **Kreatin-Auswahl:** Toggle/Chip „Kreatin" direkt im Eingabe-Screen.
  - Zustand wird **persistiert** (lokal auf der Watch, z. B. `UserDefaults`): beim nächsten Öffnen ist die
    letzte Auswahl **vorselektiert**.
  - Der gewählte Zustand wird als `withCreatine` mit der Messung gespeichert → spätere Auswertung „mit/ohne Kreatin".
- [ ] Optimistic UI: nach „Speichern" sofort neuer Wert als „letztes Gewicht" lokal, Sync läuft im Hintergrund
      (queued, auch ohne iPhone-Verbindung – wird nachgeliefert).

## C3 – iPhone-Seite & Auswertung

- [ ] iPhone empfängt Watch-Messungen (`WCSessionDelegate`), schreibt via `WeightRepository`, triggert Widget-Reload.
- [ ] iPhone sendet nach jeder Änderung „letztes Gewicht + Kreatin-Status" zurück an die Watch (`applicationContext`).
- [ ] **Auswertung im Gewichts-Tab** (aus `todo.md`): Kurve kann Messungen **mit/ohne Kreatin** unterscheiden
      (z. B. zwei Farben oder Marker), Legende „mit Kreatin / ohne". Optional Hinweis, dass Kreatin
      Wassereinlagerung ≈ +1–2 kg verursachen kann (rein informativ).
- [ ] Tests: `WeightSyncService`-Logik (Encode/Decode der Payload, Preselect-Berechnung) als Unit-Test;
      Watch-UI per SwiftUI-Preview (Hardware-Verifikation am Ende auf echtem Gerät).
- [ ] Commit `feat(C): watchOS-App + Gewichts-Komplikation mit Kreatin-Merker`.

> **Umgebungshinweis:** Komplikationen und Digital-Crown-Interaktion lassen sich headless/im Simulator nur
> begrenzt verifizieren (wie schon beim iOS-Widget dokumentiert). Logik über Unit-Tests absichern,
> End-to-End auf echter Apple Watch gegenprüfen.

---

# BLOCK D – Weitere Design- & Funktions-Verbesserungen (Repo-Check)

Kleinere, hochwirksame Verbesserungen, die beim Durchsehen aufgefallen sind.

## Design
- [ ] Konsistente Marken-Sprache: Makro-Farben **nur** aus `ColorToken` (kein inline `.blue/.orange/.pink`),
      auch im Widget und auf der Watch – ein Farbsystem über alle Plattformen.
- [ ] `MacroBar`: Zielerreichung in % anzeigen und bei Überschreitung Balken in `ColorToken.warning` färben.
- [ ] Leere Zustände freundlicher (Illustration/Icon statt reiner Text), einheitlich via `ContentUnavailableView`.
- [ ] Sanfte Mikro-Animationen & Haptik (`.sensoryFeedback`) bei Erfassen/Löschen/Zielerreichung.
- [ ] Dynamic Type XXL + Dark Mode als festen Review-Schritt für jede neue View.

## Funktion
- [ ] **Manuelle Katalog-Foods / „eigene Lebensmittel"** vollwertig verwalten (aktuell nur Quick-Add-Fallback) –
      Voraussetzung, damit Gruppen-Vorlagen dauerhaft stabile Items haben.
- [ ] **HealthKit (optional, hinter Toggle):** Gewicht nach HealthKit schreiben/lesen – passt exakt zum neuen
      Gewichts-Feature und zur Watch. Bewusst optional halten (Scope-Schutz), aber Architektur vorsehen.
- [ ] **Deep-Link-Schema `foodreflect://`** zentral definieren (Widget-Tap iOS **und** watchOS nutzen es):
      `…/weight/new`, `…/log`, `…/meal/<templateID>`.
- [ ] **OFF-Textsuche** vor Release gegen die dann erreichbare API verifizieren (offener Punkt aus README/altem TODO).
- [ ] Store-Dateiname `KalorienTracker.sqlite` in `ModelContainerFactory` bleibt aus Migrationsgründen bestehen
      (nicht umbenennen – würde Bestandsdaten „verlieren"). Nur intern kommentieren.

---

## Empfohlene Reihenfolge (gesamt)

1. `todo.md` Phase 1 (Rename), 3+4 (Ring/Dashboard), 2+5 (Tabs/Gewicht).
2. **Block A** (Datenmodell: `mealType`, `withCreatine`).
3. **Block B** (Mahlzeiten-Gruppen/Vorlagen).
4. **Block C** (Watch-App + Komplikation) – baut auf `WeightEntry` + `withCreatine` auf.
5. **Block D** (Politur, HealthKit optional, Deep-Links).

## Scope-Schutz (weiterhin außen vor)
Community, Rezepte-Import, KI-Coach, Gamification, Trainings-/Verbrauchstracking, Fasten, Wasser.
Neu **in** Scope: Gewicht, Mahlzeiten-Gruppen, Watch-App, Kreatin-Merker. HealthKit nur optional hinter Toggle.
