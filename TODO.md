# Kalorientracker – Projektplan & TODO für Claude Code

> **Anweisung an Claude Code:** Lies zuerst den Abschnitt „Kontext & Entscheidungen" vollständig.
> Arbeite dann die Phasen **strikt in Reihenfolge** ab. Nach jeder Phase: Projekt muss bauen,
> Tests müssen grün sein, dann ein Commit mit `feat(phaseN): <beschreibung>`.
> Implementiere **nichts** außerhalb des MVP-Scopes. Bei Unklarheiten: nachfragen statt raten.

---

## 1. Kontext & Entscheidungen (nicht neu diskutieren)

### Produktvision
Minimalistischer Kalorientracker. Kein MyFitnessPal-Klon. Eine App, die sich in unter
einer Sekunde verstehen lässt: Dashboard mit Restkalorien, blitzschnelles Erfassen per
Barcode oder Suche, fertig. Prioritäten: (1) Einfachheit für den Nutzer, (2) Wartbarkeit,
(3) Erweiterbarkeit, (4) Performance, (5) minimalistisches Design, (6) minimale Reibung.

### Technologie-Entscheidungen

| Bereich | Entscheidung | Begründung |
|---|---|---|
| Minimum iOS | **iOS 17.0** | Voraussetzung für SwiftData + `@Observable`. Genug Marktabdeckung 2026. |
| UI | **SwiftUI**, `@Observable`-Macro (kein ObservableObject) | Modern, weniger Boilerplate, bessere Performance durch feingranulares Diffing. |
| Architektur | **MVVM + Clean Architecture light**, modular via lokalem Swift Package | Klare Schichten (Domain → Data → Features), testbar, Domain bleibt framework-frei. „Light": keine übertriebenen Interactor/Presenter-Ebenen – für diese App-Größe wäre volles VIPER/Clean Overkill. |
| Persistenz | **SwiftData**, aber **ausschließlich hinter Repository-Protokollen** | Modern, CloudKit-Pfad eingebaut. Da nur über Protokolle angesprochen, ist ein Wechsel zu GRDB/Core Data später möglich, ohne Features anzufassen. |
| CloudKit-Readiness | Modelle **jetzt schon CloudKit-kompatibel** entwerfen: keine `@Attribute(.unique)`, alle Relationships optional, alle Properties mit Defaults | Sync kommt nach MVP; wer die Regeln jetzt ignoriert, migriert später schmerzhaft. |
| Offline/Online | **Offline-first.** Tagebuch, Ziele, Historie: 100 % lokal. Netz nur für Produkt-Lookup (Barcode/Suche), Ergebnisse werden lokal gecacht | Tracken muss im Supermarktkeller ohne Empfang funktionieren. |
| Food-API | **Open Food Facts** (v2 REST) | Kostenlos, ODbL-Lizenz, weltweit beste freie Barcode-Abdeckung, sehr gut in DE/EU, offene Community, zukunftssicher. USDA FDC (gute Generika, aber kaum Barcodes, US-lastig) und FatSecret/Nutritionix/Edamam (Kosten/Lizenzhürden) sind unterlegen. USDA als optionale zweite Quelle für generische Lebensmittel **später** – Architektur sieht das via `FoodDataSource`-Protokoll vor. |
| Barcode | **VisionKit `DataScannerViewController`** | Schnellste native Lösung, Live-Highlighting, minimal Code. Fallback AVFoundation nur falls nötig. |
| Charts | **Swift Charts** | Nativ, minimalistisch, keine Dependency. |
| DI | **Manuell: Composition Root (`AppContainer`) + Protokolle**, keine DI-Frameworks | Für diese Größe reicht das völlig, null Magie, perfekt debugbar. ViewModels bekommen Abhängigkeiten per Init. |
| Fehler | Typisierte Fehler (`DomainError`), ViewModels exponieren `ViewState` (loading/loaded/empty/error mit Retry) | Kein silent failure, kein Alert-Spam. |
| Tests | **Swift Testing** (`@Test`), Domain + ViewModels unit-getestet, Repositories mit In-Memory-SwiftData | Domain ist pure Swift → trivial testbar. |
| Sprache | Deutsch als Basis-Lokalisierung, String Catalog (`Localizable.xcstrings`) von Anfang an | Später englisch ergänzbar ohne Refactoring. |

### Bewusste Abweichungen vom Briefing (bereits entschieden)
1. **Apple Watch ist Phase 9 (nach MVP).** Komplikation erfordert eigenes watchOS-Target + WatchConnectivity-Sync. Das iPhone-Widget (Phase 7) liefert denselben Wert früher. Architektur ist vorbereitet (Domain/Data-Module sind Target-unabhängig).
2. **Tortendiagramm bleibt, wird aber ergänzt** durch drei schlanke Fortschrittsbalken (Ist/Ziel pro Makro). Ein Pie zeigt nur Verteilung, nicht Zielerreichung – beides zusammen bleibt trotzdem minimal.
3. **Schnelleintrag-Fallback ist MVP-Pflicht:** Wenn Barcode/Suche nichts liefert, kann der Nutzer Name + kcal (+ optional Makros) manuell eintragen. Ohne das ist die App bei jedem Miss eine Sackgasse. (Vollwertige „eigene Lebensmittel" mit Verwaltung bleiben Post-MVP.)
4. **Mini-Onboarding ist MVP-Pflicht:** Ein Screen, ein Eingabefeld (Tagesziel kcal), Makros werden automatisch vorgeschlagen (30 % Protein / 40 % KH / 30 % Fett, umgerechnet: `protein_g = kcal·0.30/4`, `carbs_g = kcal·0.40/4`, `fat_g = kcal·0.30/9`) und sind in den Einstellungen anpassbar.

### Explizit NICHT bauen (auch nicht „nebenbei")
Community, Rezepte, Mahlzeitenplanung, KI-Coach, Challenges, soziale Features,
Ernährungspläne, Gamification, Kalorienverbrauch/Training, HealthKit, Siri,
Live Activities, Fasten, Gewicht, Wasser, CloudKit-Sync, intelligente Vorschläge.
Diese Liste ist Scope-Schutz. Verstoß = Fehler.

---

## 2. Projektstruktur

```
KalorienTracker/
├── KalorienTracker.xcodeproj
├── App/                          # App-Target (Komposition, Einstiegspunkt)
│   ├── KalorienTrackerApp.swift  # @main, ModelContainer, AppContainer
│   ├── AppContainer.swift        # Composition Root (DI)
│   └── RootView.swift            # Onboarding vs. Dashboard
├── Widget/                       # Widget-Extension-Target (Phase 7)
├── CalorieCore/                  # Lokales Swift Package
│   ├── Package.swift
│   └── Sources/
│       ├── Domain/               # Pure Swift. KEINE Imports außer Foundation.
│       │   ├── Entities/         #   Food, DiaryEntry, MacroGoals, DayTotals, WeekStats
│       │   ├── Repositories/     #   Protokolle: DiaryRepository, GoalsRepository, FoodCatalogRepository
│       │   ├── Sources/          #   Protokoll: FoodDataSource (Remote-Lookup)
│       │   └── UseCases/         #   LogFoodUseCase, GetDayTotalsUseCase, GetWeekStatsUseCase, SuggestMacrosUseCase, RankSearchResultsUseCase
│       ├── Data/                 # SwiftData + Netzwerk. Implementiert Domain-Protokolle.
│       │   ├── Persistence/      #   SD-Modelle (SDFood, SDDiaryEntry, SDGoals), ModelContainer-Factory (App-Group-URL!), Mapper
│       │   ├── Repositories/     #   SwiftDataDiaryRepository etc.
│       │   └── OpenFoodFacts/    #   OFFClient (URLSession, async/await), DTOs, Mapper, User-Agent-Header
│       ├── DesignSystem/         #   Farben, Typo, Spacing-Tokens, Komponenten (ProgressRing, MacroBar, PrimaryButton, Card)
│       ├── FeatureDashboard/     #   DashboardView + ViewModel, Tagesring, Makros, Wochenchart
│       ├── FeatureLog/           #   Log-Sheet: Suche, Mengeneingabe, Schnelleintrag
│       ├── FeatureScanner/       #   DataScanner-Wrapper + Scan-Flow
│       └── FeatureSettings/      #   Ziele bearbeiten, Onboarding-Screen
└── Tests/ (je Target Unit-Tests im Package, UI-Smoke-Test im App-Target)
```

Abhängigkeitsregel (strikt): `Features → Domain (+ DesignSystem)`, `Data → Domain`,
`App → alles` (Composition Root). **Features importieren niemals Data.**
Domain importiert nichts außer Foundation.

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
```

CloudKit-Regeln bei den SwiftData-Modellen jetzt schon einhalten:
keine Unique-Constraints, Relationships optional, alle Properties mit Defaultwerten.
ModelContainer über App-Group-URL konfigurieren (`group.<bundleid>`), damit das
Widget in Phase 7 denselben Store liest.

---

## 4. Datenfluss & API-Konzept

**Erfassen:** View → ViewModel → `LogFoodUseCase` → `DiaryRepository.save()` →
SwiftData → ViewModel lädt Tagessummen neu → `WidgetCenter.reloadAllTimelines()` (ab Phase 7).

**Barcode:** Scan → `FoodCatalogRepository.food(barcode:)` (lokaler Cache-Hit?) →
sonst `FoodDataSource.fetchProduct(barcode:)` (OFF) → cachen → Mengen-Screen (Portion
vorausgefüllt) → 1 Tap zum Speichern. Ziel: **Scan bis gespeichert < 5 Sekunden.**

**Suche:** Debounced (300 ms) → lokaler Cache zuerst (sofortige Ergebnisse) → parallel
OFF-Suche → Ergebnisse mergen → `RankSearchResultsUseCase` sortiert nach:
(1) Vollständigkeit der Nährwerte, (2) Sprach-/Landesmatch, (3) OFF-Popularität
(`unique_scans_n`), (4) eigene `useCount`.

**Open Food Facts konkret:**
- Produkt: `GET https://world.openfoodfacts.org/api/v2/product/{barcode}?fields=product_name,brands,nutriments,serving_quantity,quantity`
- Suche: Search-a-licious / v2-Search mit `fields`-Einschränkung
- **Pflicht:** eigener `User-Agent`-Header (`KalorienTracker/1.0 (kontakt@...)`) – OFF-Richtlinie
- Rate-Limits respektieren (Suche ist limitiert → Debounce + Cache sind nicht optional)
- Fehlerfälle sauber: Timeout 10 s, kein Netz → Cache + Hinweis, Produkt nicht gefunden → Schnelleintrag anbieten

---

## 5. UI & Navigation

**Ein Screen-Prinzip.** Root = Dashboard in einem `NavigationStack`. Kein TabBar.

- **Dashboard (Root):**
  - Oben groß: verbleibende kcal (die eine Zahl, die zählt), darunter klein „konsumiert / Ziel"
  - Makro-Sektion: 3 schlanke Fortschrittsbalken (P/K/F, Ist vs. Ziel) + kompaktes Tortendiagramm der aktuellen Verteilung
  - Wochen-Karte: Swift-Charts-Balkendiagramm (7 Tage, aktuelle KW), dezente Ziellinie, darunter „Ø 2.145 kcal/Tag · 120 kcal unter Ziel"
  - Heutige Einträge als schlichte Liste (Swipe-to-delete)
  - Toolbar: Zahnrad → Settings
  - **Prominenter FAB/Bottom-Button „+"** → Log-Sheet
- **Log-Sheet (`.sheet`, medium/large Detent):** Suchfeld sofort fokussiert, Barcode-Button direkt daneben, darunter Ergebnisliste; Tap auf Ergebnis → Mengeneingabe (Slider/Stepper + Freitext g, Portions-Shortcuts) → Speichern schließt das Sheet. Fußzeile: „Schnelleintrag" (manuell kcal/Makros)
- **Scanner:** Vollbild-Cover aus dem Log-Sheet, auto-dismiss bei Treffer
- **Onboarding:** einmalig, 1 Screen (Ziel-kcal), danach nie wieder im Weg
- **Settings:** Ziel-kcal + Makro-Gramm editierbar, „Auto-Vorschlag wiederherstellen"

**Design-Tokens (DesignSystem):** systemBackground-basiert, eine Akzentfarbe,
SF-Pro-Typo mit klarer Größenhierarchie (Rest-kcal ≥ 48 pt bold rounded), 8er-Spacing-Grid,
Touch-Targets ≥ 44 pt, Dark Mode von Tag 1, Dynamic Type mindestens bis XL testen.
Keine Schatten-Orgien, keine Verläufe, kein Konfetti.

---

## 6. TODO – Phasen

### Phase 0 – Projektsetup ✅
- [x] Xcode-Projekt `KalorienTracker` (iOS 17, SwiftUI, Swift 5.10+, Strict Concurrency: complete) – generiert via XcodeGen aus `project.yml`
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
- [x] Cache-Strategie: neue `CachingFoodCatalogRepository` (Cache-Hit zuerst, sonst `FoodDataSource` + Persistieren via `SwiftDataFoodCatalogRepository`); `recordUsage` pflegt `lastUsedAt`/`useCount` (bereits Phase 2)
- [x] Tests mit gemockten URLProtocol-Responses (echte, live abgerufene OFF-Nutella-JSON als Fixture)
- [x] **DoD:** Barcode einer echten Nutella-EAN liefert gemapptes `Food` – live gegen die echte OFF-API verifiziert (curl) und als Fixture-Test abgesichert

  **Bekannte Einschränkung:** Die Textsuche (`search-a-licious`, search.openfoodfacts.org) war während der Implementierung nicht erreichbar (502) und deren Doku ebenfalls nicht. `OFFSearchResponse` dekodiert daher tolerant gegen mehrere plausible Top-Level-Feldnamen (`hits`/`products`/`results`/`docs`) und ist nur gegen selbst gebaute Fixtures getestet, nicht gegen die echte API. Vor Phase 5 (Suche im Log-Sheet) gegen die dann erreichbare API verifizieren und ggf. Feldnamen/Schema in `OFFProductDTO`/`OFFSearchResponse` anpassen.

### Phase 4 – Onboarding, Settings & Dashboard-Grundgerüst ✅
- [x] DesignSystem: Tokens (`Spacing`, `ColorToken`, `TypographyToken`) + Komponenten (`ProgressRing`, `MacroBar`, `CardBackground`, `PrimaryButton`) + gemeinsames `ViewState<Value>`
- [x] Onboarding-Screen (Ziel-kcal → `SuggestMacrosUseCase` → speichern), `RootView`-Weiche (Onboarding vs. Dashboard anhand vorhandener Ziele)
- [x] Settings: Ziele anzeigen/editieren, Auto-Vorschlag-Reset
- [x] `DashboardViewModel` (`@Observable`, `ViewState`) + Dashboard: Rest-kcal groß, konsumiert/Ziel, Makro-Balken, Tortendiagramm (Swift Charts `SectorMark`), heutige Einträge mit Swipe-to-delete
- [x] `AppContainer` vollständig verdrahtet (ModelContainer mit App-Group-Fallback, alle Repositories, OFFClient)
- [x] **DoD:** Onboarding → Dashboard-Flow läuft mit echten (leeren) Daten – im Simulator getestet (Screenshots: Onboarding, gespeicherte Ziele im Dashboard übernommen, Neuinstallation zeigt wieder Onboarding). 11 neue ViewModel-Tests. Dark-Mode-Check steht noch aus (Phase 8, Accessibility-Pass).

  **Architektur-Korrektur unterwegs:** `DashboardView` hätte ursprünglich `FeatureSettings` importiert (Verstoß gegen „Features → Domain + DesignSystem"). Stattdessen nimmt es jetzt die Settings-Destination generisch als `@ViewBuilder`-Closure entgegen, injiziert vom Composition Root (`RootView`) – Features bleiben sich gegenseitig unbekannt.

### Phase 5 – Erfassen (Suche + Schnelleintrag)
- [ ] Log-Sheet: fokussiertes Suchfeld, Debounce, Cache-first + OFF-Merge, gerankte Liste (Name, Marke, kcal/100 g)
- [ ] Mengen-Screen: Gramm-Eingabe + Portions-Shortcuts, Live-Vorschau der kcal/Makros, Speichern → Dashboard aktualisiert sofort
- [ ] Schnelleintrag: Name + kcal (Makros optional) → direkt als `DiaryEntry`
- [ ] Leere/Fehler/Offline-Zustände im Sheet (freundlich, mit Retry)
- [ ] **DoD:** Kompletter Flow „öffnen → suchen → Menge → speichern" in < 10 s von Hand machbar

### Phase 6 – Barcode-Scanner
- [ ] `DataScannerViewController`-Wrapper (UIViewControllerRepresentable), nur EAN-8/EAN-13/UPC
- [ ] Flow: Scan → Haptik → Lookup (Cache→OFF) → Mengen-Screen mit vorausgefüllter Portion; nicht gefunden → Schnelleintrag mit Barcode vorbelegt
- [ ] Kamera-Permission-Handling + Geräte ohne DataScanner-Support abfangen
- [ ] **DoD:** Scan-bis-gespeichert < 5 s auf echtem Gerät

### Phase 7 – Wochenstatistik & iPhone-Widget
- [ ] Wochen-Karte auf dem Dashboard: 7-Tage-Balkenchart + Ø-Zusammenfassung + über/unter Ziel (nutzt `GetWeekStatsUseCase`)
- [ ] Widget-Extension: small (Rest-kcal + Ring) & accessoryCircular/rectangular für Lock Screen; liest den App-Group-Store read-only
- [ ] `WidgetCenter.reloadAllTimelines()` nach jedem Log/Delete/Ziel-Update
- [ ] **DoD:** Widget zeigt nach einem Log-Vorgang binnen Sekunden den neuen Stand

### Phase 8 – Polish & Absicherung (MVP-Abschluss)
- [ ] Accessibility-Pass: VoiceOver-Labels, Dynamic Type, Kontraste
- [ ] Performance-Pass: Dashboard-Startzeit, Chart-Rendering, keine Main-Thread-Blocker
- [ ] Edge-Cases: Tageswechsel um Mitternacht, Zeitzonenwechsel, Ziel nachträglich ändern (Historie bleibt Snapshot!)
- [ ] UI-Smoke-Test (XCUITest): Onboarding → Log → Dashboard-Zahlen stimmen
- [ ] README mit Architekturüberblick + ADR-Kurznotizen (Warum SwiftData, warum OFF, …)
- [ ] **DoD: MVP fertig.**

### Phase 9 – Apple Watch (Post-MVP, erst nach Freigabe beginnen)
- [ ] watchOS-Target: Komplikationen via WidgetKit (accessoryCircular: Rest-kcal-Ring; accessoryRectangular: Rest/konsumiert)
- [ ] Datenpfad iPhone→Watch: `WCSession` mit `transferCurrentComplicationUserInfo` (kompakter Snapshot: rest, konsumiert, Ziel, Datum)
- [ ] Minimale Watch-App: eine View mit denselben drei Werten, keine Eingabe
- [ ] Später ablösbar durch CloudKit-Sync (Architektur lässt das zu)

---

## 7. Skalierungsstrategie (nur zur Orientierung, nichts bauen)
- **Neue Features = neue Feature-Targets** im Package; Domain wächst um Entities/UseCases, Data um Repositories. Bestehende Module bleiben unberührt.
- **CloudKit-Sync:** ModelConfiguration auf CloudKit umstellen – Modelle sind bereits regelkonform. Konfliktstrategie: last-write-wins pro Entry (Einträge sind append-only, daher unkritisch).
- **HealthKit/Siri/Live Activities:** eigene Data-Adapter hinter neuen Domain-Protokollen; UseCases bleiben stabil.
- **Zweite Food-Quelle (USDA):** weitere `FoodDataSource`-Implementierung + Merge im Repository.
- **Eigene Lebensmittel/Favoriten/Mahlzeiten:** `Food.source = .manual` + `useCount` existieren bereits als Fundament.

## 8. Risiken & Gegenmaßnahmen
- **OFF-Datenqualität schwankt** (fehlende/falsche Nährwerte) → Ranking bevorzugt vollständige Einträge; Werte sind vor dem Speichern sichtbar; Schnelleintrag als Ventil.
- **OFF-Rate-Limits/Ausfall** → aggressives lokales Caching, Debounce, klare Offline-States. App bleibt ohne Netz voll benutzbar (nur Neusuche eingeschränkt).
- **SwiftData-Reifegrad** → Repository-Abstraktion ist die Versicherung; keine SwiftData-Typen außerhalb von Data.
- **Scope Creep** → Abschnitt „Explizit NICHT bauen" ist bindend.
- **Tages-/Zeitzonenlogik** → `dayKey` konsequent aus lokaler Kalender-Mitternacht ableiten, in Tests fixieren.
- **Snapshot-Prinzip** → niemals Nährwerte „live" aus `Food` in die Historie rechnen; Tests decken das ab.

## 9. Arbeitsregeln für Claude Code
1. Eine Phase pro Arbeitsblock. Erst DoD erfüllen, dann committen, dann weiter.
2. Kein Code in Features, der `import Data` enthält. Kein SwiftData außerhalb von `Data` (Ausnahme: ModelContainer-Setup im App-Target + Widget-Read).
3. Jede öffentliche UseCase-Logik bekommt Tests im selben Schritt, nicht „später".
4. UI-Texte nur über den String Catalog.
5. Bei Zweifel zwischen „mehr Feature" und „weniger Reibung": immer weniger Reibung.
