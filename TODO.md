# FoodReflect – Projektplan & TODO

> **Anweisung an Claude Code:** Lies zuerst den Abschnitt „Kontext & Entscheidungen" vollständig.
> Arbeite Phasen **strikt in Reihenfolge** ab. Nach jeder Phase: Projekt muss bauen (`xcodegen generate` +
> Build), Tests müssen grün sein, dann ein Commit mit `feat(phaseN): <beschreibung>`. Die
> **Abhängigkeitsregel bleibt heilig**: `Features → Domain + DesignSystem` (nie `Data`, nie Feature↔Feature).
> Feature-zu-Feature-Navigation ausschließlich per `@ViewBuilder`-Closure aus dem Composition Root
> (`AppContainer`/`RootView`/`RootTabView`). Implementiere **nichts** außerhalb des Scopes (Abschnitt
> „Explizit NICHT bauen"). Bei Unklarheiten: nachfragen statt raten.
>
> Dieses Dokument ist die Zusammenführung von zwei ursprünglich getrennten Plänen: dem MVP-Plan (Teil A,
> „Phase 0–9") und dem darauf aufbauenden Redesign-Auftrag (Teil B, „Phase 1–7"). Beide Phasen-Zähler starten
> bewusst je bei 1 – sie spiegeln zwei getrennte Arbeitsblöcke mit eigener Commit-Historie
> (`feat(phase5)` aus dem MVP ist nicht dasselbe wie `feat(phase5)` aus dem Redesign). Der aktuelle
> Produktstand ist das Ergebnis aus **beiden** Teilen zusammen.

---

## 1. Kontext & Entscheidungen (nicht neu diskutieren)

### Produktvision
Minimalistischer Kalorientracker. Kein MyFitnessPal-Klon. Eine App, die sich schnell verstehen lässt:
vier fokussierte Tabs – **Heute** (Restkalorien, blitzschnelles Erfassen per Barcode oder Suche),
**Verlauf** (Wochen-/Monatsübersicht), **Gewicht** (Verlaufskurve) und **Einstellungen**. Prioritäten:
(1) Einfachheit für den Nutzer, (2) Wartbarkeit, (3) Erweiterbarkeit, (4) Performance, (5) minimalistisches
Design, (6) minimale Reibung.

### Technologie-Entscheidungen

| Bereich | Entscheidung | Begründung |
|---|---|---|
| Minimum iOS | **iOS 17.0** | Voraussetzung für SwiftData + `@Observable`. Genug Marktabdeckung 2026. |
| UI | **SwiftUI**, `@Observable`-Macro (kein ObservableObject) | Modern, weniger Boilerplate, bessere Performance durch feingranulares Diffing. |
| Architektur | **MVVM + Clean Architecture light**, modular via lokalem Swift Package | Klare Schichten (Domain → Data → Features), testbar, Domain bleibt framework-frei. „Light": keine übertriebenen Interactor/Presenter-Ebenen – für diese App-Größe wäre volles VIPER/Clean Overkill. |
| Persistenz | **SwiftData**, aber **ausschließlich hinter Repository-Protokollen** | Modern, CloudKit-Pfad eingebaut. Da nur über Protokolle angesprochen, ist ein Wechsel zu GRDB/Core Data später möglich, ohne Features anzufassen. |
| CloudKit-Readiness | Modelle **jetzt schon CloudKit-kompatibel** entwerfen: keine `@Attribute(.unique)`, alle Relationships optional, alle Properties mit Defaults | Sync kommt nach MVP; wer die Regeln jetzt ignoriert, migriert später schmerzhaft. |
| Offline/Online | **Offline-first.** Tagebuch, Ziele, Historie, Gewicht: 100 % lokal. Netz nur für Produkt-Lookup (Barcode/Suche), Ergebnisse werden lokal gecacht | Tracken muss im Supermarktkeller ohne Empfang funktionieren. |
| Food-API | **Open Food Facts** (v2 REST) | Kostenlos, ODbL-Lizenz, weltweit beste freie Barcode-Abdeckung, sehr gut in DE/EU, offene Community, zukunftssicher. USDA FDC (gute Generika, aber kaum Barcodes, US-lastig) und FatSecret/Nutritionix/Edamam (Kosten/Lizenzhürden) sind unterlegen. USDA als optionale zweite Quelle für generische Lebensmittel **später** – Architektur sieht das via `FoodDataSource`-Protokoll vor. |
| Barcode | **VisionKit `DataScannerViewController`** | Schnellste native Lösung, Live-Highlighting, minimal Code. Fallback AVFoundation nur falls nötig. |
| Charts | **Swift Charts** | Nativ, minimalistisch, keine Dependency. |
| DI | **Manuell: Composition Root (`AppContainer`) + Protokolle**, keine DI-Frameworks | Für diese Größe reicht das völlig, null Magie, perfekt debugbar. ViewModels bekommen Abhängigkeiten per Init. |
| Fehler | Typisierte Fehler (`DomainError`), ViewModels exponieren `ViewState` (loading/loaded/empty/error mit Retry) | Kein silent failure, kein Alert-Spam. |
| Tests | **Swift Testing** (`@Test`), Domain + ViewModels unit-getestet, Repositories mit In-Memory-SwiftData | Domain ist pure Swift → trivial testbar. |
| Sprache | Deutsch als Basis-Lokalisierung, String Catalog (`Localizable.xcstrings`) von Anfang an | Später englisch ergänzbar ohne Refactoring. |

### Bewusste Abweichungen vom ursprünglichen Briefing (bereits entschieden)
1. **Apple Watch ist Phase 9 des MVP-Plans (nach MVP-Abschluss, eigene Freigabe nötig).** Komplikation
   erfordert eigenes watchOS-Target + WatchConnectivity-Sync. Das iPhone-Widget (MVP-Phase 7) liefert
   denselben Wert früher. Architektur ist vorbereitet (Domain/Data-Module sind Target-unabhängig). **Stand:**
   weiterhin nicht begonnen, wartet auf explizite Freigabe.
2. **Tortendiagramm bleibt, wird aber ergänzt** durch drei schlanke Fortschrittsbalken (Ist/Ziel pro Makro). Ein Pie zeigt nur Verteilung, nicht Zielerreichung – beides zusammen bleibt trotzdem minimal.
3. **Schnelleintrag-Fallback ist Pflicht:** Wenn Barcode/Suche nichts liefert, kann der Nutzer Name + kcal (+ optional Makros) manuell eintragen. Ohne das ist die App bei jedem Miss eine Sackgasse. (Vollwertige „eigene Lebensmittel" mit Verwaltung bleiben Post-MVP.)
4. **Mini-Onboarding ist Pflicht:** Ein Screen, ein Eingabefeld (Tagesziel kcal), Makros werden automatisch vorgeschlagen (30 % Protein / 40 % KH / 30 % Fett, umgerechnet: `protein_g = kcal·0.30/4`, `carbs_g = kcal·0.40/4`, `fat_g = kcal·0.30/9`) und sind in den Einstellungen anpassbar.
5. **Redesign (siehe Teil B) hat das Ein-Screen-Prinzip zugunsten einer 4-Tab-Navigation aufgegeben** und
   Gewicht-Tracking bewusst als eigenen Tab ergänzt (siehe Punkt „Gewicht" unten).

### Explizit NICHT bauen (auch nicht „nebenbei")
Community, Rezepte, Mahlzeitenplanung, KI-Coach, Challenges, soziale Features, Ernährungspläne,
Gamification, Kalorienverbrauch/Training, HealthKit, Siri, Live Activities, Fasten, Wasser,
CloudKit-Sync (Readiness ja, Aktivierung nein), intelligente Vorschläge.
Diese Liste ist Scope-Schutz. Verstoß = Fehler.

> **Historische Anmerkung zu „Gewicht":** Im ursprünglichen MVP-Plan stand „Gewicht" explizit auf dieser
> Nicht-Ziele-Liste (Scope-Schutz für den MVP). Der Redesign-Auftrag (Teil B, Phase 5) hat diesen Ausschluss
> bewusst aufgehoben und Gewichts-Tracking als vollwertigen, eigenen Tab spezifiziert – seitdem ist Gewicht
> **in** Scope und wurde aus dieser Liste gestrichen. Alle anderen Punkte gelten unverändert fort.

---

## 2. Projektstruktur

```
FoodReflect/
├── FoodReflect.xcodeproj         # generiert via XcodeGen aus project.yml, nicht eingecheckt
├── App/                          # App-Target (Komposition, Einstiegspunkt)
│   ├── FoodReflectApp.swift      # @main, ModelContainer, AppContainer
│   ├── AppContainer.swift        # Composition Root (DI)
│   ├── RootView.swift            # Weiche: Onboarding vs. RootTabView
│   └── RootTabView.swift         # TabView: Heute / Verlauf / Gewicht / Einstellungen
├── Widget/                       # Widget-Extension-Target
├── CalorieCore/                  # Lokales Swift Package
│   ├── Package.swift
│   └── Sources/
│       ├── Domain/               # Pure Swift. KEINE Imports außer Foundation.
│       │   ├── Entities/         #   Food, DiaryEntry, MacroGoals, DayTotals, WeekStats, WeightEntry, WeightTrend
│       │   ├── Repositories/     #   Protokolle: DiaryRepository, GoalsRepository, FoodCatalogRepository, WeightRepository
│       │   ├── Sources/          #   Protokolle: FoodDataSource (Remote-Lookup), WidgetRefreshing
│       │   └── UseCases/         #   LogFoodUseCase, GetDayTotalsUseCase, GetWeekStatsUseCase, SuggestMacrosUseCase, RankSearchResultsUseCase, GetWeightTrendUseCase
│       ├── Data/                 # SwiftData + Netzwerk. Implementiert Domain-Protokolle.
│       │   ├── Persistence/      #   SD-Modelle (SDFood, SDDiaryEntry, SDGoals, SDWeightEntry), ModelContainer-Factory (App-Group-URL!), Mapper
│       │   ├── Repositories/     #   SwiftDataDiaryRepository, SwiftDataWeightRepository etc.
│       │   └── OpenFoodFacts/    #   OFFClient (URLSession, async/await), DTOs, Mapper, User-Agent-Header
│       ├── DesignSystem/         #   Farben/Typo/Spacing-Tokens, Komponenten (SegmentedProgressRing, MacroBar, PrimaryButton, CardBackground), ViewState<Value>
│       ├── FeatureDashboard/     #   Tab „Heute": Rest-kcal-Ring, Makros, heutige Einträge, Eintrag-Detail
│       ├── FeatureHistory/       #   Tab „Verlauf": Wochen-/Monats-Chart, Tages-Detail
│       ├── FeatureLog/           #   Log-Sheet: Suche, Mengeneingabe, Schnelleintrag
│       ├── FeatureScanner/       #   DataScanner-Wrapper + Scan-Flow
│       ├── FeatureSettings/      #   Tab „Einstellungen": Onboarding, Ziele-Verwaltung, Über/Info
│       └── FeatureWeight/        #   Tab „Gewicht": Verlaufskurve, Eintragen, vollständige Historie
└── Tests/ (je Target Unit-Tests im Package, UI-Smoke-Test im App-Target)
```

**Abhängigkeitsregel (strikt):** `Features → Domain + DesignSystem` (nie `Data`, nie sich gegenseitig).
`Data → Domain`. `App → alles` (Composition Root). Domain importiert nichts außer Foundation. Wo eine
Feature-View auf eine andere verweisen muss (z. B. Dashboard → Log-Sheet → Scanner), wird die Ziel-View
generisch als `@ViewBuilder`-Closure injiziert – die Verdrahtung passiert ausschließlich im
`AppContainer`/`RootView`/`RootTabView` (Composition Root). So bleiben Feature-Module unabhängig testbar und
kompilierbar, ohne voneinander zu wissen.

---

## 3. Datenmodell

Domain-Entities (structs, framework-frei) — SwiftData-Modelle in Data spiegeln sie:

```swift
struct Food {                     // Katalog-Eintrag (Cache aus OFF oder manuell)
    let id: UUID
    var name: String
    var brand: String?
    var barcode: String?
    var kcalPer100g: Double       // Normalisierung: IMMER pro 100 g/ml speichern
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var servingSizeGrams: Double? // typische Portion, falls bekannt
    var source: FoodSource        // .openFoodFacts(code:) | .manual
    var lastUsedAt: Date?
    var useCount: Int             // Basis für spätere „intelligente Vorschläge"
}

struct DiaryEntry {               // Tagebucheintrag – DENORMALISIERTER SNAPSHOT
    let id: UUID
    var consumedAt: Date
    var dayKey: String            // "2026-07-13" – schnelle Tagesabfragen
    var foodName: String          // Snapshot! Späteres Editieren des Foods darf
    var amountGrams: Double       // die Historie nicht verändern.
    var kcal: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var foodID: UUID?             // optionale Referenz (CloudKit-Regel: optional)
}

struct MacroGoals {
    var dailyKcal: Int
    var proteinGrams: Int
    var carbsGrams: Int
    var fatGrams: Int
    var isCustomized: Bool        // false = Auto-Vorschlag aktiv
}

struct WeightEntry {              // Gewichtsmessung (Redesign, Phase 5)
    let id: UUID
    var dayKey: String            // dieselbe Tages-/Bereichslogik wie DiaryEntry
    var weightKg: Double
    var recordedAt: Date
}
```

CloudKit-Regeln bei den SwiftData-Modellen jetzt schon einhalten:
keine Unique-Constraints, Relationships optional, alle Properties mit Defaultwerten.
ModelContainer über App-Group-URL konfigurieren (`group.com.bjoernnnn.foodreflect`), damit das
Widget denselben Store liest.

---

## 4. Datenfluss & API-Konzept

**Erfassen:** View → ViewModel → `LogFoodUseCase` → `DiaryRepository.save()` →
SwiftData → ViewModel lädt Tagessummen neu → `WidgetCenter.reloadAllTimelines()`.

**Barcode:** Scan → `FoodCatalogRepository.food(barcode:)` (lokaler Cache-Hit?) →
sonst `FoodDataSource.fetchProduct(barcode:)` (OFF) → cachen → Mengen-Screen (Portion
vorausgefüllt) → 1 Tap zum Speichern. Ziel: **Scan bis gespeichert < 5 Sekunden.**

**Suche:** Debounced (300 ms) → lokaler Cache zuerst (sofortige Ergebnisse) → parallel
OFF-Suche → Ergebnisse mergen → `RankSearchResultsUseCase` sortiert nach:
(1) Vollständigkeit der Nährwerte, (2) Sprach-/Landesmatch, (3) OFF-Popularität
(`unique_scans_n`), (4) eigene `useCount`.

**Gewicht:** View → `WeightViewModel` → `WeightRepository.save()` → SwiftData → ViewModel lädt Verlauf neu →
`WidgetCenter.reloadAllTimelines()`. Dieselbe `dayKey`-Logik wie beim Tagebuch, eigener Repository-Pfad,
kein `Food`-Bezug.

**Open Food Facts konkret:**
- Produkt: `GET https://world.openfoodfacts.org/api/v2/product/{barcode}?fields=product_name,brands,nutriments,serving_quantity,quantity`
- Suche: Search-a-licious / v2-Search mit `fields`-Einschränkung
- **Pflicht:** eigener `User-Agent`-Header (`FoodReflect/1.0 (kontakt@...)`) – OFF-Richtlinie
- Rate-Limits respektieren (Suche ist limitiert → Debounce + Cache sind nicht optional)
- Fehlerfälle sauber: Timeout 10 s, kein Netz → Cache + Hinweis, Produkt nicht gefunden → Schnelleintrag anbieten

**Bekannte Einschränkung:** Die Textsuche (`search-a-licious`, search.openfoodfacts.org) war während der
MVP-Implementierung (2026-07-13) nicht erreichbar (502) und deren Doku ebenfalls nicht. `OFFSearchResponse`
dekodiert daher tolerant gegen mehrere plausible Top-Level-Feldnamen (`hits`/`products`/`results`/`docs`) und
ist nur gegen selbst gebaute Fixtures getestet, nicht gegen die echte API. Vor einem Release gegen die dann
erreichbare, echte API verifizieren.

---

## 5. UI & Navigation

**Vier fokussierte Tabs** (`RootTabView`, Redesign Phase 2) – vorher ein reines Ein-Screen-Prinzip ohne
TabBar, das mit dem Redesign zugunsten der folgenden Struktur aufgegeben wurde:

- **Tab „Heute" (`FeatureDashboard`, Root):**
  - Oben groß, zentriert: **mehrfarbiger Segment-Ring** (ein Segment pro Makro: Protein/KH/Fett) mit der
    verbleibenden kcal-Zahl in der Mitte (die eine Zahl, die zählt), darunter „konsumiert / Ziel"
  - Makro-Sektion: 3 schlanke Fortschrittsbalken (P/K/F, Ist vs. Ziel, mit Prozent-Zielerreichung) + kompaktes Tortendiagramm der aktuellen Verteilung
  - Heutige Einträge als schlichte Liste (Swipe-to-delete, Tap → Eintrag-Detail zum Editieren/Löschen)
  - **Prominenter Bottom-Button „Erfassen"** → Log-Sheet
- **Tab „Verlauf" (`FeatureHistory`):** Wochen-/Monatsübersicht als Swift-Charts-Balkendiagramm mit
  Ziellinie + Ø-Zusammenfassung, Tap auf einen Tag → Tages-Detail (alle Einträge, Makro-Aufschlüsselung).
- **Tab „Gewicht" (`FeatureWeight`):** aktuelle Gewichtszahl + Delta zur letzten Messung, Verlaufskurve über
  wählbaren Zeitraum (Woche/Monat/Alle), Eintragen per Sheet, vollständige Historie mit Bearbeiten/Löschen.
- **Tab „Einstellungen" (`FeatureSettings`):** Ziel-kcal + Makro-Gramm editierbar, „Auto-Vorschlag
  wiederherstellen", Über/Info (Version, OFF/ODbL-Lizenzhinweis, Datenschutz).
- **Log-Sheet (`.sheet`, medium/large Detent):** Suchfeld sofort fokussiert, Barcode-Button direkt daneben, darunter Ergebnisliste; Tap auf Ergebnis → Mengeneingabe (Slider/Stepper + Freitext g, Portions-Shortcuts) → Speichern schließt das Sheet. Fußzeile: „Schnelleintrag" (manuell kcal/Makros)
- **Scanner:** Vollbild-Cover aus dem Log-Sheet, auto-dismiss bei Treffer
- **Onboarding:** einmalig, 1 Screen (Ziel-kcal), danach nie wieder im Weg

**Design-Tokens (DesignSystem):** systemBackground-basiert, eine Akzentfarbe + Makro-Farben (`proteinColor`,
`carbsColor`, `fatColor`) zentral in `ColorToken`, SF-Pro-Typo mit klarer Größenhierarchie (Rest-kcal ≥ 48 pt
bold rounded, `@ScaledMetric`), 8er-Spacing-Grid, Touch-Targets ≥ 44 pt, Dark Mode von Tag 1, Dynamic Type
bis XXL getestet. Animationen dezent (`.easeInOut`/`.easeOut`, keine Spring-Overkill). Keine Schatten-Orgien,
keine Verläufe, kein Konfetti.

---

## 6. Teil A — TODO-Phasen (MVP, Phase 0–9)

### Phase 0 – Projektsetup ✅
- [x] Xcode-Projekt (iOS 17, SwiftUI, Swift 5.10+, Strict Concurrency: complete) – generiert via XcodeGen aus `project.yml`
- [x] Lokales Package `CalorieCore` mit Targets: `Domain`, `Data`, `DesignSystem`, `FeatureDashboard`, `FeatureLog`, `FeatureScanner`, `FeatureSettings` + Test-Targets; Abhängigkeiten gemäß Abschnitt 2 verdrahten
- [x] App-Group-Capability + Entitlement anlegen (`group.<bundleid>`)
- [x] String Catalog anlegen; `.gitignore`; SwiftLint/SwiftFormat-Konfiguration (schlank)
- [x] `AppContainer` (Composition Root) als Skelett
- [x] **DoD:** leere App baut & startet, Package-Tests laufen (auch wenn leer)

### Phase 1 – Domain ✅
- [x] Entities: `Food`, `DiaryEntry`, `MacroGoals`, `DayTotals`, `WeekStats`, `FoodSource`, `DomainError`
- [x] Repository-Protokolle: `DiaryRepository`, `GoalsRepository`, `FoodCatalogRepository`; Remote-Protokoll `FoodDataSource`
- [x] UseCases: `SuggestMacrosUseCase` (30/40/30-Formel), `LogFoodUseCase` (Menge → Snapshot-Berechnung aus per-100g), `GetDayTotalsUseCase`, `GetWeekStatsUseCase` (Ø, über/unter Ziel), `RankSearchResultsUseCase`
- [x] Unit-Tests für alle UseCases (Rundung, Randfälle: 0 g, Ziel 0, leere Woche, unvollständige Nährwerte)
- [x] **DoD:** Domain-Target framework-frei, 100 % der UseCases getestet (21 Tests grün)

### Phase 2 – Data (Persistenz) ✅
- [x] SwiftData-Modelle `SDFood`, `SDDiaryEntry`, `SDGoals` (CloudKit-Regeln!), Mapper ↔ Domain
- [x] `ModelContainerFactory` mit App-Group-Store-URL + In-Memory-Variante für Tests
- [x] Repositories implementieren; `dayKey`-basierte Tagesabfrage, Wochenabfrage
- [x] Repository-Tests gegen In-Memory-Container
- [x] **DoD:** Speichern/Laden/Löschen von Einträgen + Zielen funktioniert, Tests grün (14 Repository-Tests)

### Phase 3 – Data (Open Food Facts) ✅
- [x] `OFFClient`: `fetchProduct(barcode:)` + `search(query:)`, async/await, User-Agent, `fields`-Filter, 10-s-Timeout, typisierte Fehler
- [x] DTOs + Mapper → `Food` (Normalisierung auf 100 g; kJ→kcal falls nötig; unvollständige Produkte werden über `kcalPer100g == 0` + `RankSearchResultsUseCase`-Completeness-Gewichtung statt eines eigenen Flags markiert)
- [x] Cache-Strategie: `CachingFoodCatalogRepository` (Cache-Hit zuerst, sonst `FoodDataSource` + Persistieren via `SwiftDataFoodCatalogRepository`); `recordUsage` pflegt `lastUsedAt`/`useCount` (bereits Phase 2)
- [x] Tests mit gemockten URLProtocol-Responses (echte, live abgerufene OFF-Nutella-JSON als Fixture)
- [x] **DoD:** Barcode einer echten Nutella-EAN liefert gemapptes `Food` – live gegen die echte OFF-API verifiziert (curl) und als Fixture-Test abgesichert

  **Bekannte Einschränkung:** siehe Abschnitt 4, „Bekannte Einschränkung" zur OFF-Textsuche.

### Phase 4 – Onboarding, Settings & Dashboard-Grundgerüst ✅
- [x] DesignSystem: Tokens (`Spacing`, `ColorToken`, `TypographyToken`) + Komponenten (`ProgressRing`, `MacroBar`, `CardBackground`, `PrimaryButton`) + gemeinsames `ViewState<Value>`
- [x] Onboarding-Screen (Ziel-kcal → `SuggestMacrosUseCase` → speichern), `RootView`-Weiche (Onboarding vs. Dashboard anhand vorhandener Ziele)
- [x] Settings: Ziele anzeigen/editieren, Auto-Vorschlag-Reset
- [x] `DashboardViewModel` (`@Observable`, `ViewState`) + Dashboard: Rest-kcal groß, konsumiert/Ziel, Makro-Balken, Tortendiagramm (Swift Charts `SectorMark`), heutige Einträge mit Swipe-to-delete
- [x] `AppContainer` vollständig verdrahtet (ModelContainer mit App-Group-Fallback, alle Repositories, OFFClient)
- [x] **DoD:** Onboarding → Dashboard-Flow läuft mit echten (leeren) Daten – im Simulator getestet (Screenshots: Onboarding, gespeicherte Ziele im Dashboard übernommen, Neuinstallation zeigt wieder Onboarding). 11 neue ViewModel-Tests.

  **Architektur-Korrektur unterwegs:** `DashboardView` hätte ursprünglich `FeatureSettings` importiert (Verstoß gegen „Features → Domain + DesignSystem"). Stattdessen nimmt es die Settings-Destination generisch als `@ViewBuilder`-Closure entgegen, injiziert vom Composition Root (`RootView`) – Features bleiben sich gegenseitig unbekannt. (Dieser Closure-Parameter wurde in Redesign-Phase 2 wieder entfernt, als Settings ein eigener Tab wurde.)

### Phase 5 – Erfassen (Suche + Schnelleintrag) ✅
- [x] Log-Sheet: fokussiertes Suchfeld, Debounce (300 ms via `.task(id:)`), Cache-first + OFF-Merge (Duplikate per Barcode dedupliziert, lokaler Treffer gewinnt), gerankte Liste (Name, Marke, kcal/100 g) via `RankSearchResultsUseCase`
- [x] Mengen-Screen (`AmountEntryView`): Gramm-Eingabe + Portions-Shortcuts (Serving-Size + 50/100/150/200 g), Live-Vorschau der kcal/Makros über `LogFoodUseCase`, Speichern → `recordUsage` + Dashboard lädt beim Schließen neu
- [x] Schnelleintrag (`QuickAddView`): Name + kcal (Makros optional) → direkt als `DiaryEntry`
- [x] Leere/Fehler/Offline-Zustände im Sheet (freundlich, mit Retry) über `ViewState`
- [x] **DoD:** Flow-Logik vollständig unit-getestet (5 `LogViewModel`-Tests: Merge, Dedup, Remote-Fehler-Toleranz). Der komplette Flow „öffnen → Erfassen → speichern → Dashboard aktualisiert" ist per XCUITest abgesichert (Phase 8) – lief erfolgreich in ca. 11 s durch, unter der 10-s-Zielmarke.

### Phase 6 – Barcode-Scanner ✅ (code-complete, Geräte-DoD offen)
- [x] `DataScannerViewController`-Wrapper (UIViewControllerRepresentable), nur EAN-8/EAN-13/UPC-E (UPC-A wird von VisionKit als EAN-13 erkannt)
- [x] Flow: Scan → Haptik → Lookup (Cache→OFF via `CachingFoodCatalogRepository`) → `AmountEntryView` mit vorausgefüllter Portion; nicht gefunden → `QuickAddView` mit Barcode-Hinweis vorbelegt
- [x] Kamera-Permission-Handling (`AVCaptureDevice.authorizationStatus`, Link zu Einstellungen bei Ablehnung) + `DataScannerViewController.isSupported`-Check für Geräte ohne Unterstützung
- [ ] **DoD:** Scan-bis-gespeichert < 5 s auf echtem Gerät – **nicht verifizierbar in dieser Entwicklungsumgebung.** `DataScannerViewController` erfordert echte Kamera-Hardware (Neural Engine); im Simulator ist `isSupported == false` (dokumentiertes Apple-Verhalten, kein Bug). Code baut fehlerfrei, Fallback-UI ist implementiert; der eigentliche Scan-Flow muss auf einem echten iPhone getestet werden.

### Phase 7 – Wochenstatistik & iPhone-Widget ✅ (Geräte-DoD offen)
- [x] Wochen-Karte: 7-Tage-Balkenchart (Swift Charts `BarMark` + `RuleMark`-Ziellinie) + Ø-Zusammenfassung + über/unter Ziel (nutzt `GetWeekStatsUseCase`). **Im Redesign (Teil B, Phase 6) vom Dashboard in den eigenen „Verlauf"-Tab gewandert.**
- [x] Widget-Extension (`Widget/`, XcodeGen-Target `app-extension`, in die App embedded): small (Rest-kcal + Ring) & `accessoryCircular`/`accessoryRectangular` für Lock Screen; `CalorieTimelineProvider` liest den App-Group-Store read-only über dieselben Repositories/UseCases wie die App
- [x] `WidgetRefreshing`-Protokoll (Domain) + `WidgetCenterRefresher` (Data) injiziert in alle mutierenden ViewModels (Dashboard, Log, Settings, später Weight) – `WidgetCenter.reloadAllTimelines()` läuft nach jeder Mutation
- [x] Geteilte `AppGroup.id`-Konstante (Data) statt dupliziertem String in App + Widget
- [ ] **DoD:** Widget zeigt nach einem Log-Vorgang binnen Sekunden den neuen Stand – **nicht verifizierbar in dieser Umgebung.** Home-/Lock-Screen-Widgets lassen sich nicht headless hinzufügen/screenshotten; App+Widget-Extension bauen zusammen fehlerfrei, Logik ist unit-getestet (`reloadCount`-Assertions), aber der visuelle End-to-End-Check gehört auf ein echtes Gerät oder eine interaktive Simulator-Sitzung.

### Phase 8 – Polish & Absicherung (MVP-Abschluss) ✅
- [x] Accessibility-Pass: VoiceOver-Labels (`accessibilityLabel` auf Icon-only-Buttons), dekorative Ring-Instanzen per `accessibilityHidden` ausgeblendet, `MacroBar`/Eintragszeilen/Charts zu je einem sprechenden Accessibility-Element kombiniert (`accessibilityElement(children:)` + `accessibilityValue`), Rest-kcal-Anzeige von fixer Font-Size auf `@ScaledMetric` umgestellt (Dynamic Type)
- [x] Performance-Pass: `DashboardViewModel.load()` holte Tageseinträge zuvor doppelt – behoben, ein Fetch wird wiederverwendet (`GetDayTotalsUseCase.aggregate` statt vollem UseCase-Aufruf)
- [x] Edge-Cases: Mitternachts-/Zeitzonenwechsel über `scenePhase`-Reload abgefangen; Ziel nachträglich ändern ohne Auswirkung auf Historie ist strukturell durch das Snapshot-Prinzip in `LogFoodUseCase` garantiert und getestet
- [x] UI-Smoke-Test (XCUITest): Onboarding → Schnelleintrag (500 kcal) → Dashboard zeigt korrekt aktualisierte Zahlen – lief erfolgreich durch, End-to-End im Simulator verifiziert. Startet deterministisch über `-UITestReset`-Launch-Argument (frischer In-Memory-Store).
- [x] README mit Architekturüberblick + ADR-Kurznotizen
- [x] **DoD: MVP fertig.** Alle 9 Phasen des ursprünglichen Briefings umgesetzt; 65 Unit-/Integrationstests + 1 XCUITest grün; App + Widget-Extension bauen fehlerfrei; Nicht-Ziele wurden nicht verletzt. Offene Punkte für ein echtes Gerät vor Release: Barcode-Scan (Phase 6) und Widget-Rendering (Phase 7) visuell/zeitlich verifizieren.

### Phase 9 – Apple Watch (Post-MVP, wartet auf Freigabe) ⏸️
- [ ] watchOS-Target: Komplikationen via WidgetKit (accessoryCircular: Rest-kcal-Ring; accessoryRectangular: Rest/konsumiert)
- [ ] Datenpfad iPhone→Watch: `WCSession` mit `transferCurrentComplicationUserInfo` (kompakter Snapshot: rest, konsumiert, Ziel, Datum)
- [ ] Minimale Watch-App: eine View mit denselben drei Werten, keine Eingabe
- [ ] Später ablösbar durch CloudKit-Sync (Architektur lässt das zu)
- **Status:** noch nicht begonnen. Braucht eine separate, explizite Freigabe, bevor daran gearbeitet wird.

---

## 7. Teil B — TODO-Phasen (Redesign zu „FoodReflect", Phase 1–7)

Kontext: Das MVP (Teil A) war funktional vollständig, aber optisch/strukturell zurückhaltend (Ein-Screen-
Prinzip, einfarbiger Ring, kein Gewichts-Tracking). Der Redesign-Auftrag baut darauf auf, ohne die
Architektur umzuwerfen – „Verbesserungen, kein Umbau".

### Phase 1 – Rename zu „FoodReflect" ✅
- [x] `project.yml`: Name/Targets/Scheme von `KalorienTracker` auf `FoodReflect` umgestellt (Bundle-Prefix war bereits `com.bjoernnnn.foodreflect`).
- [x] `App/KalorienTrackerApp.swift` → `App/FoodReflectApp.swift`, `struct KalorienTrackerApp` → `struct FoodReflectApp`.
- [x] `App/Info.plist`-Pfade und `App/FoodReflect.entitlements` angepasst.
- [x] `CFBundleDisplayName` gesetzt: **FoodReflect** (App und Widget).
- [x] `KalorienTrackerUITests/` → `FoodReflectUITests/`, Klassen-/Referenznamen angepasst.
- [x] `README.md` und globale Referenzen aktualisiert (`OFFClient`-User-Agent, `ModelContainerFactory`-Store-Dateiname `FoodReflect.sqlite`, Tests).
- [x] App-Group-ID unverändert `group.com.bjoernnnn.foodreflect`.
- [x] Build + alle 65 Package-Tests + XCUITest grün.
- [ ] Optional (nicht gemacht): App-Icon/Launch-Screen an neuen Namen anpassen (kein neues Asset vorgegeben).

### Phase 2 – Navigation auf TabView umstellen ✅
- [x] `App/RootTabView.swift`: TabView mit vier Tabs (Heute/Verlauf/Gewicht/Einstellungen, zunächst mit
      Platzhaltern für Verlauf und Gewicht).
- [x] `RootView.swift` verdrahtet jetzt `RootTabView` statt direkt `DashboardView`.
- [x] Settings aus der Dashboard-Toolbar in einen eigenen Tab verschoben; `DashboardView`s generischer
      `SettingsDestination`-Parameter entfernt; `SettingsView` bekam einen eigenen `NavigationStack`.
- [x] TabBar-Akzentfarbe gesetzt (`.tint(ColorToken.accent)`).
- [x] UITest `testTabNavigation` ergänzt. **Erkenntnis:** `.accessibilityIdentifier` auf Tab-Inhalten
      propagiert nicht zum TabBar-Button – funktioniert nur über den sichtbaren Label-Text
      (`app.tabBars.buttons["Verlauf"]`).
- [x] Build + alle 65 Package-Tests + 2 XCUITests grün.

### Phase 3 – Mehrfarbiger Makro-Ring ✅
- [x] `ColorToken`: `proteinColor`/`carbsColor`/`fatColor` ergänzt, überall statt inline-Farben verwendet.
- [x] Neue Komponente `SegmentedProgressRing` (gestapelte `Circle().trim(from:to:)`-Bögen, `RingSegment`-
      Wertetyp, Restbogen als Track, Übertrag bei Zielüberschreitung in `ColorToken.warning`).
- [x] Komplett auf `SegmentedProgressRing` migriert (auch im Widget) statt das alte `ProgressRing` zu
      behalten; `ProgressRing.swift` danach ungenutzt und gelöscht.
- [x] Rest-kcal-Zahl bleibt in der Ring-Mitte, Makro-Legende darunter zentriert.
- [x] Visuell per XCUITest-Screenshot verifiziert (Ring, Legende, Farben, TabBar).
- [x] Build + alle 65 Package-Tests + App+Widget-Build grün.

### Phase 4 – Dashboard-Redesign: zentrieren & aufwerten ✅
- [x] Hero-Sektion (Ring + Legende + konsumiert-Zeile) zentriert (`VStack` + `frame(maxWidth: .infinity)` +
      `multilineTextAlignment(.center)`), nicht mehr linksbündig in der List-Row.
- [x] Ring vergrößert (200→230pt), weicher unscharfer Glow-Hintergrund statt hartem Schatten.
- [x] `MacroBar` zeigt Prozent-Zielerreichung rechts in Makro-Farbe.
- [x] Sanfte Auftritts-Animation: Ring startet bei 0, animiert beim ersten Erscheinen hoch (`.easeOut(0.8s)`).
- [x] Card-Optik vereinheitlicht (`cardBackground()` cornerRadius 24 + dezenter Schatten, zentral für alle Cards).
- [x] Leerzustand „Heutige Einträge" freundlicher formuliert (Tray-Symbol).
- [x] Haptisches Feedback (`.sensoryFeedback(.success, trigger:)`) bei Erfassen/Löschen.
- [x] Visuell verifiziert (Light + Dark) per XCUITest-Screenshot.
- [x] Build + alle 65 Package-Tests + 2 XCUITests grün.

### Phase 5 – Gewichts-Tracking (Domain → Data → Feature) ✅
- [x] Domain: `WeightEntry`-Entity, `WeightRepository`-Protokoll, `GetWeightTrendUseCase`
      (`WeightTrend`: `latest`/`averageWeightKg`/`deltaFromPreviousMeasurement`).
- [x] Data: `SDWeightEntry`, `WeightEntryMapper`, `SwiftDataWeightRepository` (`@ModelActor`), im
      `ModelContainerFactory`-Schema registriert.
- [x] Feature: neues Package-Target `FeatureWeight` (`WeightViewModel`, `WeightView` mit
      Segment-Picker Woche/Monat/Alle, Swift-Charts-Verlaufskurve, `WeightEntrySheet` zum Eintragen,
      Swipe-to-delete). lb-Umschaltung bewusst als Post-MVP im Code kommentiert, nicht gebaut.
- [x] Verdrahtung: `WeightRepository` in `AppContainer`, `WeightView` ersetzt den Platzhalter im „Gewicht"-Tab.
- [x] Tests: `FeatureWeightTests` (4) + `SwiftDataWeightRepositoryTests` (6) + `GetWeightTrendUseCaseTests` (4).
- [x] Visuell per XCUITest-Screenshot verifiziert (Delta-Anzeige, Chart, Verlaufsliste).
- [x] Nebenbei: verwaistes `KalorienTracker.xcodeproj` (Rest vom Rename, nie von Git getrackt) lokal entfernt.
- [x] Build + alle 61 Package-Tests + 2 XCUITests grün.

### Phase 6 – Sinnvolle Unterseiten ✅
- [x] **Verlauf-Tab (`HistoryView`, neues Package-Target `FeatureHistory`)**: Wochen-/Monatsübersicht
      (Balkendiagramm + Ziellinie + Ø/Delta-Text), Segment-Picker. Wiederverwendet `GetWeekStatsUseCase`
      unverändert (zeitraumagnostisch, kein separater `GetMonthStatsUseCase` nötig). Der „Diese Woche"-Chart
      ist vom Dashboard hierher gewandert.
- [x] **Tages-Detail (`DayDetailView`, in `FeatureHistory`)**: Tap auf einen Tag → alle Einträge dieses
      Tages, Makro-Aufschlüsselung, Zielerreichung. Eigenes `DayDetailViewModel`.
- [x] **Eintrag-Detail (`EntryDetailView`, in `FeatureDashboard`)**: Tap auf einen Eintrag im Dashboard →
      volle Nährwerte, Menge editieren (proportionale Skalierung aus dem Nährwert-Snapshot, kein
      Food-Lookup), löschen. `DiaryEntry` dafür auf `Hashable` erweitert.
- [x] **Gewicht-Historie (`WeightHistoryView`, in `FeatureWeight`)**: vollständige Tabelle aller Messungen
      (`WeightViewModel.loadAll()`), Bearbeiten (vorbefülltes Sheet) und Löschen. Teilt sich das
      `WeightViewModel` mit `WeightView`. `WeightViewModel.save` unterstützt optional `entryID:` für
      Edit-in-place.
- [x] **Über/Info in Settings (`AboutView`)**: Version, OFF/ODbL-Lizenzhinweis, Datenschutz-Hinweis „alles
      lokal". Settings nutzt dafür `.navigationDestination(for: SettingsPushDestination.self)`.
- [x] Jede Unterseite: leerer/Fehler-Zustand via `ContentUnavailableView`.
- [x] Visuell per XCUITest-Screenshots verifiziert (alle fünf neuen Screens).
- [x] Nebenbei: `FakeDiaryRepository.save` in Tests auf echtes Upsert-by-id korrigiert (war nur `append`).
- [x] Build + alle 90 Package-Tests + 2 XCUITests grün.

### Phase 7 – Politur & Konsistenz ✅
- [x] Makro-Farben global auf `ColorToken` geprüft (ein `#Preview`-Ausreißer in `MacroBar.swift` korrigiert).
- [x] Widget an neues Branding angeglichen (`configurationDisplayName` „Kalorien" → „FoodReflect"; Ring-Farben
      nutzten `ColorToken` bereits konsistent zum Dashboard).
- [x] Animationen geprüft: nur `SegmentedProgressRing` animiert (`.easeInOut`/`.easeOut`), bewusst dezent;
      Tab-Wechsel/Sheets nutzen SwiftUI-Standardanimationen.
- [x] Accessibility: VoiceOver-Labels/Values für Charts geprüft, Ring bleibt bewusst `accessibilityHidden`
      (Makro-Detail redundant im Donut-Chart), Tabs nutzen `Label(...)`. Dynamic Type XXL
      (`accessibility-extra-extra-extra-large`) für die Phase-6-Screens getestet – kein Clipping.
- [x] Dark Mode für alle Phase-6-Views per Screenshot geprüft – guter Kontrast.
- [x] `swiftlint`/`swiftformat` sauber; README-Architekturbaum aktualisiert (`FeatureWeight`,
      `FeatureHistory`, `RootTabView`, 4-Tab-Struktur statt „Ein-Screen-Prinzip").
- [x] Alten `Gewicht`-Widerspruch in den Nicht-Zielen aufgelöst (siehe Abschnitt 1).
- [x] Finaler Durchlauf: kein physisches Gerät in dieser Umgebung verfügbar (wie schon in MVP-Phase 6/7) –
      stattdessen vollständiger Simulator-Durchlauf (Light Mode) + gezielte Dark-Mode-/XXL-Screenshots.
      Vor einem echten Release weiterhin auf echtem Gerät gegenprüfen (Ring, Scanner, Widget, Tabs).
- [x] Build + alle 90 Package-Tests + 2 XCUITests grün.

---

## 8. Skalierungsstrategie (nur zur Orientierung, nichts bauen)
- **Neue Features = neue Feature-Targets** im Package; Domain wächst um Entities/UseCases, Data um Repositories. Bestehende Module bleiben unberührt.
- **CloudKit-Sync:** ModelConfiguration auf CloudKit umstellen – Modelle sind bereits regelkonform. Konfliktstrategie: last-write-wins pro Entry (Einträge sind append-only, daher unkritisch).
- **HealthKit/Siri/Live Activities:** eigene Data-Adapter hinter neuen Domain-Protokollen; UseCases bleiben stabil.
- **Zweite Food-Quelle (USDA):** weitere `FoodDataSource`-Implementierung + Merge im Repository.
- **Eigene Lebensmittel/Favoriten/Mahlzeiten:** `Food.source = .manual` + `useCount` existieren bereits als Fundament.
- **Apple Watch:** siehe Teil A, Phase 9 (Architektur ist vorbereitet, Umsetzung wartet auf Freigabe).

## 9. Risiken & Gegenmaßnahmen
- **OFF-Datenqualität schwankt** (fehlende/falsche Nährwerte) → Ranking bevorzugt vollständige Einträge; Werte sind vor dem Speichern sichtbar; Schnelleintrag als Ventil.
- **OFF-Rate-Limits/Ausfall** → aggressives lokales Caching, Debounce, klare Offline-States. App bleibt ohne Netz voll benutzbar (nur Neusuche eingeschränkt).
- **SwiftData-Reifegrad** → Repository-Abstraktion ist die Versicherung; keine SwiftData-Typen außerhalb von Data.
- **Scope Creep** → Abschnitt „Explizit NICHT bauen" ist bindend.
- **Tages-/Zeitzonenlogik** → `dayKey` konsequent aus lokaler Kalender-Mitternacht ableiten, in Tests fixieren.
- **Snapshot-Prinzip** → niemals Nährwerte „live" aus `Food` in die Historie rechnen; Tests decken das ab.

## 10. Arbeitsregeln für Claude Code
1. Eine Phase pro Arbeitsblock. Erst DoD erfüllen, dann committen, dann weiter.
2. Kein Code in Features, der `import Data` enthält. Kein SwiftData außerhalb von `Data` (Ausnahme: ModelContainer-Setup im App-Target + Widget-Read).
3. Jede öffentliche UseCase-Logik bekommt Tests im selben Schritt, nicht „später".
4. UI-Texte nur über den String Catalog.
5. Bei Zweifel zwischen „mehr Feature" und „weniger Reibung": immer weniger Reibung.
6. Feature-zu-Feature-Navigation ausschließlich per generischer `@ViewBuilder`-Closure aus dem Composition
   Root, nie per direktem Feature-Import.
