# FoodReflect

Minimalistischer Kalorientracker (iOS 17+, SwiftUI). Vier fokussierte Tabs – Heute, Verlauf,
Gewicht, Einstellungen –, blitzschnelles Erfassen per Barcode oder Suche. Vollständiger Scope,
alle Phasen-DoDs und explizite Nicht-Ziele: siehe `TODO.md`.

## Setup

Das Xcode-Projekt wird nicht eingecheckt, sondern per [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml` generiert:

```sh
brew install xcodegen
xcodegen generate
open FoodReflect.xcodeproj
```

Nach jeder Änderung an `project.yml` erneut `xcodegen generate` ausführen.

## Tests

```sh
# App + Widget-Extension
xcodebuild test -project FoodReflect.xcodeproj -scheme FoodReflect \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Package (Domain, Data, Features) – von innerhalb CalorieCore/
cd CalorieCore && xcodebuild test -scheme CalorieCore-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# UI-Smoke-Test (XCUITest)
xcodebuild test -project FoodReflect.xcodeproj -scheme FoodReflect \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:FoodReflectUITests
```

## Lint & Format

```sh
swiftlint lint
swiftformat .
```

## Architekturüberblick

```
FoodReflect/
├── App/                  Composition Root: AppContainer (DI), RootView (Onboarding-Weiche), RootTabView (4 Tabs)
├── Widget/                WidgetKit-Extension, liest den App-Group-Store read-only
└── CalorieCore/           Lokales Swift Package
    └── Sources/
        ├── Domain/         Pure Swift (nur Foundation). Entities, Repository-Protokolle, UseCases.
        ├── Data/           SwiftData-Modelle + Repositories, OpenFoodFacts-Client. Implementiert Domain-Protokolle.
        ├── DesignSystem/   Tokens (Spacing/Color/Typography), Komponenten, ViewState<Value>
        ├── FeatureDashboard/  Tab „Heute": Rest-kcal-Ring, Makros, heutige Einträge, Eintrag-Detail
        ├── FeatureHistory/    Tab „Verlauf": Wochen-/Monats-Chart, Tages-Detail
        ├── FeatureLog/        Log-Sheet: Suche, Mengeneingabe, Schnelleintrag
        ├── FeatureScanner/    Barcode-Scanner (VisionKit)
        ├── FeatureSettings/   Tab „Einstellungen": Onboarding, Ziele-Verwaltung, Über/Info
        └── FeatureWeight/     Tab „Gewicht": Verlaufskurve, Eintragen, vollständige Historie
```

**Abhängigkeitsregel (strikt):** `Features → Domain + DesignSystem` (nie `Data`, nie sich
gegenseitig). Wo eine Feature-View auf eine andere verweisen muss (z. B. Dashboard →
Settings, Log-Sheet → Scanner), wird die Ziel-View generisch als `@ViewBuilder`-Closure
injiziert – die Verdrahtung passiert ausschließlich im `AppContainer`/`RootView`
(Composition Root). So bleiben Feature-Module unabhängig testbar und kompilierbar, ohne
voneinander zu wissen.

**Datenfluss:** View → ViewModel (`@Observable`, exponiert `ViewState`) → UseCase/Repository
(Protokoll aus `Domain`) → konkrete Implementierung (`Data`, per Init injiziert). Tests
verwenden In-Memory-Fakes derselben Protokolle – nie die echten `Data`-Typen in
Domain-/Feature-Tests.

## Architecture Decision Records (Kurzfassung)

**Warum SwiftData statt Core Data/GRDB/Realm?**
Modern, nativer CloudKit-Sync-Pfad für später eingebaut, deutlich weniger Boilerplate als
Core Data. Da ausschließlich hinter Repository-Protokollen angesprochen (`SwiftDataDiaryRepository`
etc.), ist ein späterer Wechsel möglich, ohne Feature-Code anzufassen.

**Warum Open Food Facts statt USDA/FatSecret/Nutritionix/Edamam?**
Kostenlos, ODbL-Lizenz, weltweit beste freie Barcode-Abdeckung, sehr gut in DE/EU. USDA hat
kaum Barcodes und ist US-lastig; die kommerziellen APIs haben Kosten-/Lizenzhürden. Über das
`FoodDataSource`-Protokoll ist eine zweite Quelle später ergänzbar, ohne bestehenden Code zu
ändern.

**Warum `@ModelActor` für die Repositories?**
Unter Swift 6 Strict Concurrency ist `ModelContext` nicht `Sendable`. `@ModelActor` synthetisiert
einen Actor mit eigenem, isoliertem `ModelContext` pro `ModelContainer` – sicherer Zugriff aus
beliebigen Tasks, ohne manuelles Locking.

**Warum denormalisierte Snapshots im Tagebuch (`DiaryEntry`) statt Live-Referenz auf `Food`?**
Nährwerte werden zum Erfassungszeitpunkt in `DiaryEntry` eingefroren (`LogFoodUseCase`).
Ändert sich später ein Katalog-Eintrag oder das Tagesziel, bleibt die Historie unverändert –
das ist Produktanforderung, nicht nur Implementierungsdetail, und ist in
`LogFoodUseCaseTests` explizit abgesichert.

**Warum generische `@ViewBuilder`-Closures statt eines DI-Frameworks für Feature-zu-Feature-Navigation?**
Kein DI-Framework, keine Magie (Projektvorgabe). Die Alternative wäre, dass Feature-Module
sich gegenseitig importieren – das würde die Abhängigkeitsregel verletzen und Module
gegenseitig koppeln. Die Closure-Injektion ist reines Swift/SwiftUI, hält Module blind
füreinander und macht die Composition Root zum einzigen Ort, der alle Module kennt.

**Bekannte Einschränkung: Open-Food-Facts-Textsuche (`search-a-licious`)**
Die empfohlene Suche-API war während der Implementierung (2026-07-13) nicht erreichbar (502)
und ihre Doku ebenfalls nicht. `OFFSearchResponse` dekodiert deshalb tolerant gegen mehrere
plausible Top-Level-Feldnamen (`hits`/`products`/`results`/`docs`). Vor einem Release gegen
die dann erreichbare, echte API verifizieren (Details in `TODO.md`, Phase 3/5).

## Bekannte Grenzen dieser Umgebung (nicht der App)

Einzelne DoDs aus `TODO.md` konnten in der Entwicklungsumgebung dieser Session nicht
end-to-end verifiziert werden, weil die nötige Hardware/Interaktion fehlte:
- **Barcode-Scanner (Phase 6):** `DataScannerViewController.isSupported` ist im Simulator
  dokumentiert `false` (erfordert Neural Engine/echte Kamera) – Code baut fehlerfrei,
  Fallback-UI ist implementiert, Verifikation nur auf echtem Gerät möglich.
- **Widget (Phase 7):** Home-/Lock-Screen-Widgets lassen sich headless nicht platzieren/screenshotten.
- **Vollständiger manueller Klick-Durchlauf (Phase 5):** Synthetische Mausklicks wurden von
  der Automatisierungsumgebung nicht zuverlässig durchgereicht; die Logik ist stattdessen
  über Unit-Tests und den XCUITest-Smoke-Test abgesichert.

Diese Punkte sind reine Umgebungs-Limitierungen der Entwicklungssitzung, keine bekannten
App-Bugs – vor einem Release dennoch auf einem echten Gerät gegenprüfen.
