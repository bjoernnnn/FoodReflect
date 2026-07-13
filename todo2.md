# FoodReflect – Redesign & Feature-TODO

> **Anweisung an Claude Code / den umsetzenden Entwickler:** Arbeite die Phasen **strikt in Reihenfolge** ab.
> Nach jeder Phase muss das Projekt bauen (`xcodegen generate` + Build) und alle Tests grün sein, dann Commit mit
> `feat(phaseN): <beschreibung>`. Die **Abhängigkeitsregel bleibt heilig**: `Features → Domain + DesignSystem`
> (nie `Data`, nie Feature↔Feature). Feature-zu-Feature-Navigation ausschließlich per `@ViewBuilder`-Closure aus
> dem Composition Root (`AppContainer`/`RootView`).

---

## 0. Analyse-Zusammenfassung (Ist-Zustand)

Sauber geschnittenes SwiftUI-Projekt (iOS 17+, SwiftData, modular via lokalem Swift Package `CalorieCore`).
Das Fundament ist gut – die folgenden Punkte sind Verbesserungen, kein Umbau.

| Bereich | Ist | Soll |
|---|---|---|
| App-Name | `KalorienTracker` (Target, `@main`-Struct, README) | **FoodReflect** (Bundle-IDs nutzen bereits `foodreflect`) |
| Navigation | Ein-Screen-Prinzip, kein TabBar | **TabView** mit Heute / Verlauf / Gewicht / Einstellungen |
| Rest-kcal-Ring | Einfarbig (`ProgressRing`, ein `tint`) | **Mehrfarbiger Ring**: Segmente pro Makro (Protein/KH/Fett) |
| Makro-Anzeige | Pie-Chart + 3 Balken, in Card | Zentriert, prominenter, animiert |
| Zentrierung | List-basiert, links ausgerichtet | Hero-Bereich (Ring + Makros) **zentriert** |
| Gewicht | Explizit nicht gebaut (Scope-Schutz im alten TODO) | **Eigener Tab** mit Verlaufskurve |
| Unterseiten | nur Settings + Log-Sheet | + Verlauf-Detail, Eintrag-Detail, Gewicht-Historie |

> **Hinweis zum alten `TODO.md`:** Dort steht „Gewicht" explizit unter *NICHT bauen* (Scope-Schutz des MVP).
> Diese Anforderung hebt das bewusst auf. Den entsprechenden Satz im alten `TODO.md` streichen bzw. dieses
> Dokument als maßgeblich markieren, damit kein Widerspruch bleibt.

---

## Phase 1 – Rename zu „FoodReflect" ✅

Ziel: konsistenter Produktname überall. Bundle-Prefix ist bereits `com.bjoernnnn.foodreflect`, nur die
sichtbaren/Target-Namen ziehen nach.

- [x] `project.yml`: `name: KalorienTracker` → `name: FoodReflect`; Target `KalorienTracker` → `FoodReflect`,
      Scheme entsprechend; Test-Target `KalorienTrackerUITests` → `FoodReflectUITests` (+ `TEST_TARGET_NAME`).
- [x] Ordner `App/` bleibt, aber `App/KalorienTrackerApp.swift` → `App/FoodReflectApp.swift`, `struct KalorienTrackerApp` → `struct FoodReflectApp`.
- [x] `App/Info.plist`-Pfad-Ausschlüsse und `App/KalorienTracker.entitlements` → `App/FoodReflect.entitlements` (Pfad in `project.yml` angepasst).
- [x] `CFBundleDisplayName` gesetzt: **FoodReflect** (App und Widget).
- [x] Widget-Anzeigename angepasst (`Kalorien-Widget` → `FoodReflect`), Bundle-ID bleibt `…foodreflect.Widget`.
- [x] Ordner `KalorienTrackerUITests/` → `FoodReflectUITests/`; Klassen-/Referenznamen angepasst.
- [x] `README.md`: Titel, alle Kommandos/Schemenamen, Architektur-Baum aktualisiert.
- [x] Globales Suchen nach „KalorienTracker" ersetzt: `project.yml`, App-Sourcen, `OFFClient`-User-Agent,
      `ModelContainerFactory`-Store-Dateiname (`FoodReflect.sqlite`), Tests. (`TODO.md` bleibt als historisches
      Protokoll der MVP-Phasen mit dem damaligen Namen stehen, wird bei der Dokumenten-Zusammenführung bereinigt.)
- [x] App-Group-ID unverändert `group.com.bjoernnnn.foodreflect`.
- [x] `xcodegen generate` neu ausgeführt, Build + alle 65 Package-Tests + XCUITest grün.
- [ ] Optional: Marketing – App-Icon/Launch-Screen an neuen Namen anpassen (nicht gemacht, kein neues Asset vorgegeben).

---

## Phase 2 – Navigation auf TabView umstellen (Voraussetzung für Gewichts-Tab) ✅

Das Ein-Screen-Prinzip wird zur **Tab-Navigation** erweitert. `RootView` bleibt die Weiche Onboarding↔App,
verdrahtet aber jetzt eine `RootTabView`. Composition Root bleibt der einzige Ort, der alle Features kennt.

- [x] Neue View `App/RootTabView.swift` mit `TabView`:
  - Tab „Heute" → `DashboardView` (SF Symbol `flame.fill`)
  - Tab „Verlauf" → Platzhalter (SF Symbol `chart.bar.fill`), echte `HistoryView` folgt in Phase 6
  - Tab „Gewicht" → Platzhalter (SF Symbol `scalemass.fill`), echte `WeightView` folgt in Phase 5
  - Tab „Einstellungen" → `SettingsView` (SF Symbol `gearshape.fill`)
- [x] `RootView.swift` (case `.true`) auf `RootTabView` umgebaut; alle Repository-/Closure-Injektionen dorthin
      durchgereicht (wie bisher pro Feature-View).
- [x] Settings wandert aus der Dashboard-Toolbar in einen eigenen Tab → Zahnrad-Toolbar-Item im Dashboard entfernt.
      **Entscheidung:** kein Shortcut belassen, da redundant zur TabBar; `DashboardView`s generischer
      `SettingsDestination`-Parameter komplett entfernt (kleinere API), `SettingsView` bekam dafür ihren eigenen
      `NavigationStack` (vorher von der Push-Navigation des Dashboards mitgenutzt).
- [x] Akzentfarbe für die TabBar gesetzt (`.tint(ColorToken.accent)`).
- [x] UITest-Smoke: `FoodReflectUITests` um `testTabNavigation` erweitert (rotiert durch alle vier Tabs und zurück).
      **Erkenntnis:** `.accessibilityIdentifier` auf dem Tab-Inhalt propagiert nicht zum TabBar-Button-Element;
      funktioniert zuverlässig nur über den sichtbaren Label-Text (`app.tabBars.buttons["Verlauf"]` etc.).
- [x] Build + alle 65 Package-Tests + 2 XCUITests grün, Commit `feat(phase2): TabView-Navigation`.

---

## Phase 3 – Mehrfarbiger Makro-Ring (Kern des Redesigns) ✅

Der einfarbige Rest-kcal-Ring wird durch einen **segmentierten Ring** ersetzt: jedes Makro bekommt seinen
Anteil an den konsumierten kcal als farbiges Segment. Das ist die zentrale „spannendere" Design-Änderung.

**Farbschema (zentral als Tokens definieren, nicht inline):**

- [x] In `ColorToken.swift` Makro-Farben ergänzt (statt inline `.blue/.orange/.pink` überall):
  `proteinColor` (Blau), `carbsColor` (Orange/Amber), `fatColor` (Pink/Magenta) – exakt wie vorgeschlagen.
  `DashboardView` (Ring, Pie-Chart, `MacroBar`-Aufrufe) und Widget nutzen jetzt ausschließlich diese Tokens.

**Neue Komponente `SegmentedProgressRing`:**

- [x] Neue Datei `CalorieCore/Sources/DesignSystem/Components/SegmentedProgressRing.swift`.
- [x] API: `SegmentedProgressRing(segments: [RingSegment], total: Double, lineWidth: CGFloat = 14)`, wobei
      `RingSegment` ein kleiner `value`+`color`-Wertetyp ist (klarer als anonyme Tupel).
- [x] Rendering: gestapelte `Circle().trim(from:to:)`-Bögen, kumulative Start-/End-Winkel, `lineCap: .round`,
      `rotationEffect(-90°)`, `.easeInOut`-Animation auf Wertänderung.
- [x] Rest-Bogen in `ColorToken.secondaryBackground` als Track darunter.
- [x] Überschreitung des Ziels sichtbar gemacht: Segmente skalieren dann auf die tatsächliche Summe (Ring wird
      voll statt einfach abgeschnitten), der Übertrag wird als eigener Bogen in `ColorToken.warning` angehängt.
- [x] `#Preview` für „im Ziel" und „über dem Ziel"; `accessibilityLabel`/`accessibilityValue` direkt auf der
      Komponente (Aufrufer können sie zusätzlich `accessibilityHidden` setzen, wenn ein kombiniertes Eltern-Element
      wie im Dashboard sinnvoller ist – dort weiterhin so gelöst, um Doppel-Ansagen zu vermeiden).
- [x] **Entscheidung:** komplett auf `SegmentedProgressRing` migriert statt das alte `ProgressRing` nur fürs
      Widget zu behalten – auch das Widget zeigt jetzt die echte Makro-Aufteilung (nicht nur Gesamtfortschritt),
      für maximale Konsistenz App↔Widget. Das alte `ProgressRing.swift` war danach komplett unbenutzt und wurde
      gelöscht (kein totes UI-Code).

**Ring-Zentrum:**

- [x] Rest-kcal-Zahl bleibt in der Ring-Mitte (`@ScaledMetric`, `rounded`), darunter „kcal übrig".
- [x] Makro-Legende (drei farbige Punkte + `P`/`K`/`F`) direkt unter dem Ring, zentriert.
- [x] Visuell verifiziert über einen temporären XCUITest-Screenshot-Attachment (`xcrun xcresulttool export
      attachments`) statt unzuverlässiger Klick-Automatisierung – Ring, Legende, Farben und TabBar sehen wie
      erwartet aus (Screenshot danach nicht committet, war nur zur Verifikation).
- [x] Build + alle 65 Package-Tests + App+Widget-Build grün, Commit `feat(phase3): mehrfarbiger Makro-Ring`.

---

## Phase 4 – Dashboard-Redesign: zentrieren & spannender machen ✅

Der Hero-Bereich (Ring + Makros) wird optisch aufgewertet und **horizontal zentriert**. Weg von der reinen
List-Optik hin zu einem klaren, mittigen Fokus.

- [x] Hero-Sektion (Ring + Legende + konsumiert-Zeile) in einen zentrierten `VStack` mit `frame(maxWidth: .infinity)`
      und `multilineTextAlignment(.center)` gesetzt; nicht mehr linksbündig in der `List`-Row.
- [x] Ring vergrößert (200pt → 230pt) und mit weichem, unscharfem Verlauf (`Circle().blur(radius: 30)` in
      `ColorToken.accent.opacity(0.12)`) hinterlegt statt eines harten `.shadow`.
- [x] Makro-Balken (`MacroBar`) bekamen eine Prozent-Zielerreichung rechts (`· 53%`, in der jeweiligen Makro-Farbe).
- [x] Sanfte Auftritts-Animation: `SegmentedProgressRing` startet bei 0 und animiert beim ersten Erscheinen
      (`.onAppear`) mit `.easeOut(duration: 0.8)` auf die vollen Bogen-Werte hoch.
- [x] Card-Optik vereinheitlicht: `cardBackground()` cornerRadius 20 → 24 + `.shadow(color: .black.opacity(0.06),
      radius: 12, y: 4)` zentral in `CardBackground.swift`, wirkt auf alle Cards (Makro-Card, Wochen-Card, später
      auch Gewicht/Verlauf).
- [x] „Heutige Einträge"-Leerzeile freundlicher formuliert + Tray-Symbol (`Label(..., systemImage: "tray")`).
- [x] Haptisches Feedback: `.sensoryFeedback(.success, trigger: viewModel.todayEntries.count)` auf der Liste –
      deckt sowohl Erfassen (Reload nach Log-Sheet-Dismiss ändert die Anzahl) als auch Löschen ab, ohne zwei
      getrennte Trigger pflegen zu müssen.
- [x] Dynamic Type: Ring-Zahl bereits via `@ScaledMetric` (Phase 8 des alten TODOs). Dark Mode visuell verifiziert
      (siehe unten) – guter Kontrast, Glow bleibt dezent sichtbar, TabBar-Akzentfarbe funktioniert in beiden Modi.
- [x] Visuell verifiziert (Light + Dark) über denselben XCUITest-Screenshot-Mechanismus wie Phase 3
      (`xcrun simctl ui <device> appearance dark/light` + `xcresulttool export attachments`); Screenshots waren
      nur zur Verifikation, nicht committet.
- [x] Build + alle 65 Package-Tests + 2 XCUITests grün, Commit `feat(phase4): Dashboard zentriert & mehrfarbiger Ring`.

---

## Phase 5 – Gewichts-Tracking (Domain → Data → Feature)

Eigener Tab nur fürs Gewicht. Sauber durch alle Schichten, damit CloudKit-Readiness (keine `@Attribute(.unique)`,
optionale Relationships, Defaults) erhalten bleibt.

**Domain:**

- [x] Entity `CalorieCore/Sources/Domain/Entities/WeightEntry.swift`: `id: UUID`, `dayKey: String`,
      `weightKg: Double`, `recordedAt: Date`. `Identifiable, Hashable, Sendable`.
- [x] Protokoll `CalorieCore/Sources/Domain/Repositories/WeightRepository.swift`:
      `entries(fromDayKey:toDayKey:)`, `latest()`, `save(_:)`, `delete(entryID:)` – jeweils `async throws(DomainError)`.
- [x] `GetWeightTrendUseCase` (Domain-Entity `WeightTrend`: `latest`, `averageWeightKg`, `deltaFromPreviousMeasurement`)
      inkl. `static func aggregate(entries:)` als reine, testbare Funktion, analog zu `GetWeekStatsUseCase`.
      4 Tests in `GetWeightTrendUseCaseTests` (leer, eine Messung, mehrere Messungen, Sortierunabhängigkeit).

**Data:**

- [x] SwiftData-Modell `CalorieCore/Sources/Data/Persistence/SDWeightEntry.swift` (alle Properties mit Defaults, kein unique).
- [x] `WeightEntryMapper.swift` (Domain ↔ SD), analog zu `DiaryEntryMapper`.
- [x] `SwiftDataWeightRepository.swift` als `@ModelActor`, analog zu `SwiftDataDiaryRepository`. 6 Tests
      (`SwiftDataWeightRepositoryTests`, In-Memory-SwiftData): speichern/lesen, Bereichsabfrage, `latest()`, Löschen, Update statt Duplikat.
- [x] Modell in `ModelContainerFactory` (App-Group- **und** In-Memory-Schema) registriert:
      `Schema([SDFood.self, SDDiaryEntry.self, SDGoals.self, SDWeightEntry.self])`.

**Feature:**

- [x] Neues Package-Target `FeatureWeight` in `CalorieCore/Package.swift` (Products + Target + Test-Target,
      `dependencies: Domain, DesignSystem`).
- [x] `WeightViewModel.swift` (`@Observable @MainActor`, `ViewState<[WeightEntry]>` + `trend: WeightTrend?`),
      lädt Verlauf (`load(daysBack:)`), speichert (`save(weightKg:date:)`) und löscht (`delete(entryID:)`) –
      speichern/löschen stoßen `widgetRefreshing.reloadTimelines()` an. 4 Tests grün.
- [x] `WeightView.swift`:
  - Oben große aktuelle Gewichtszahl (zentriert, `TypographyToken.remainingKcal`), darunter Delta zur letzten
    Messung mit Pfeil-Icon, grün (`ColorToken.positive`, neu ergänzt) bei Abnahme / orange bei Zunahme.
  - **Swift-Charts-Verlaufskurve** (`LineMark` + `PointMark`) über wählbaren Zeitraum (Segmented Picker:
    Woche/Monat/Alle), in `.cardBackground()`.
  - Sheet (`WeightEntrySheet`) zum Eintragen (Zahl per `.decimalPad` + `DatePicker`, Einheit kg; lb-Umschaltung
    bewusst weggelassen und als Post-MVP im Code kommentiert, wie im Auftrag vorgesehen).
  - Swipe-to-delete auf Einträge in der Verlaufsliste.
- [x] Verdrahtung: `WeightRepository` in `AppContainer` erzeugt (`SwiftDataWeightRepository`), per Init an
      `WeightView` im `RootTabView` gereicht (ersetzt den `WeightTabPlaceholder` aus Phase 2 vollständig).
- [x] `project.yml`: App-Target-Dependency `FeatureWeight` ergänzt, `xcodegen generate` gelaufen.
- [x] Tests: `FeatureWeightTests` (VM mit In-Memory-Fake, 4 Tests) + `SwiftDataWeightRepositoryTests` (6 Tests).
- [x] Visuell verifiziert per XCUITest-Screenshot (zwei Messungen 82.5 kg → 81.2 kg, Delta „↘ 1.3 kg zur
      letzten Messung" in Grün, Chart + Verlaufsliste korrekt); temporärer Test danach gelöscht.
- [x] Beim Aufräumen zusätzlich ein verwaistes `KalorienTracker.xcodeproj` (Rest vom Rename in Phase 1,
      nie von Git getrackt da `*.xcodeproj` global ignoriert wird) lokal entfernt.
- [x] Build + alle 61 Package-Tests (Domain 25 + Data 32 + FeatureWeight 4) + 2 XCUITests grün,
      Commit `feat(phase5): Gewichts-Tab mit Verlaufskurve`.

---

## Phase 6 – Sinnvolle Unterseiten

Unterseiten, die den bestehenden Datenfluss ergänzen (jeweils per `NavigationStack`-Push innerhalb ihres Tabs).

- [x] **Verlauf-Tab (`HistoryView`, neues Package-Target `FeatureHistory`)**: Wochen-/Monatsübersicht der kcal
      (Balkendiagramm + gestrichelte Ziellinie + Ø/Delta-Text), Segmented Picker Woche/Monat. Wiederverwendet
      `GetWeekStatsUseCase` unverändert (die UseCase ist trotz des Namens zeitraumagnostisch – nimmt beliebig
      viele `dayKeys`, daher kein separater `GetMonthStatsUseCase` nötig). Der bisherige „Diese Woche"-Chart ist
      vom Dashboard hierher gewandert (Dashboard zeigt jetzt nur noch Ring + Makros + heutige Einträge).
- [x] **Tages-Detail (`DayDetailView`, in `FeatureHistory`)**: Tippen auf einen Tag im Verlauf → alle Einträge
      dieses Tages, Makro-Aufschlüsselung (`MacroBar` x3), Zielerreichung (`kcal / Ziel`). Eigenes
      `DayDetailViewModel` lädt selbstständig über `diaryRepository.entries(on:)` + `GetDayTotalsUseCase.aggregate`.
- [x] **Eintrag-Detail (`EntryDetailView`, in `FeatureDashboard`)**: Tippen auf einen Eintrag im Dashboard → volle
      Nährwerte, Menge editieren (skaliert kcal/Makros proportional zum Nährwert-Snapshot des Eintrags – kein
      Food-Lookup, damit spätere Food-Änderungen die Historie nicht verfälschen), löschen. Dashboard lädt nach
      Rückkehr automatisch neu (Closure-Callback, kein Polling). `DiaryEntry` ist dafür jetzt `Hashable`
      (für `NavigationLink(value:)`/`navigationDestination(for:)`).
- [x] **Gewicht-Historie (`WeightHistoryView`, in `FeatureWeight`)**: vollständige Tabelle aller Messungen
      (nicht nur die 90-Tage-Vorgabe von `WeightView` – neue `WeightViewModel.loadAll()`), mit Bearbeiten (Tap
      öffnet `WeightEntrySheet` vorbefüllt) und Löschen (Swipe). Teilt sich absichtlich das `WeightViewModel`
      mit `WeightView` (eine Quelle der Wahrheit), erreichbar über einen neuen Toolbar-Link "Verlauf".
      `WeightViewModel.save` unterstützt jetzt optional `entryID:` für Edit-in-place statt Duplikat.
- [x] **Über/Info in Settings (`AboutView`)**: Version (aus `Bundle.main`), Open-Food-Facts/ODbL-Lizenzhinweis,
      Datenschutz-Hinweis „alles lokal, keine Cloud-Synchronisation, kein Tracking". Settings nutzt dafür
      jetzt `.navigationDestination(for: SettingsPushDestination.self)` (Konsistenz mit den anderen Tabs).
- [x] Jede Unterseite: leerer/Fehler-Zustand via `ContentUnavailableView`, konsistent mit Dashboard.
- [x] Visuell verifiziert per XCUITest-Screenshots (Eintrag-Detail, Verlauf-Chart, Tages-Detail,
      Gewichts-Historie, Über-FoodReflect) – alle korrekt gerendert; temporärer Test danach gelöscht.
- [x] Beim Aufräumen zusätzlich ein zweiter architektonischer Nebeneffekt: `FakeDiaryRepository.save` in den
      Tests machte bisher kein Upsert-by-id (nur `append`) – für den Eintrag-Detail-Edit-Test korrigiert, jetzt
      konsistent mit dem echten `SwiftDataDiaryRepository.save`-Verhalten.
- [x] Build + alle 90 Package-Tests (Domain 25 + Data 32 + FeatureDashboard 8 + FeatureHistory 6 + FeatureLog 5 +
      FeatureScanner 1 + FeatureSettings 7 + FeatureWeight 6) + 2 XCUITests grün,
      Commit `feat(phase6): Unterseiten (Verlauf, Detail, Gewicht-Historie, Info)`.

---

## Phase 7 – Politur & Konsistenz

- [x] Alle Makro-Farben kommen aus `ColorToken` (kein inline `.blue/.orange/.pink` mehr) – global geprüft
      (`grep` über `CalorieCore/Sources`, `App`, `Widget`). Einziger Treffer war der `#Preview` in
      `MacroBar.swift` (`tint: .blue`) – auf `ColorToken.proteinColor` umgestellt.
- [x] Widget an neue Farben/Namen angleichen: Ring-Farben nutzten in `CalorieWidgetView.swift` bereits
      `ColorToken.protein/carbs/fatColor` (identisch zum Dashboard-Ring). `configurationDisplayName` war noch
      der alte generische Name „Kalorien" (aus KalorienTracker-Zeiten) – auf „FoodReflect" umgestellt, damit
      die Widget-Galerie im Homescreen zum neuen Branding passt.
- [x] Animationen geprüft: einzige explizite Animation im ganzen Projekt ist `SegmentedProgressRing`
      (`.easeInOut` / `.easeOut(duration: 0.8)` für Ring-Trim) – bewusst dezent. Tab-Wechsel und
      Sheet-Präsentationen nutzen die SwiftUI-Standardanimationen ohne Overrides, kein Overkill.
- [x] Accessibility: Ring bleibt bewusst `accessibilityHidden` (Makro-Detail steht redundant als
      `accessibilityValue` auf dem Donut-Chart darunter, keine Doppel-Ansage); Gewichtskurve/Verlauf-Chart
      haben je ein `accessibilityLabel` + `accessibilityValue` mit Klartext-Zusammenfassung; Tabs nutzen
      `Label(...)`, das VoiceOver automatisch benennt. Dynamic Type XXL (`accessibility-extra-extra-extra-large`)
      per `xcrun simctl ui <device> content_size` getestet für Tages-Detail, Gewicht-Tab und Über-FoodReflect:
      Text umbricht korrekt, keine abgeschnittenen Inhalte, Listen bleiben scrollbar.
- [x] Dark Mode (`xcrun simctl ui <device> appearance dark`) für alle Phase-6-Views per Screenshot geprüft
      (Tages-Detail, Gewicht-Tab, Über-FoodReflect) – guter Kontrast auf dunklem `systemBackground`,
      Makro-/Delta-Farben bleiben gut lesbar.
- [x] `swiftlint lint` + `swiftformat .` sauber (0 Verstöße). README-Architekturbaum aktualisiert: `FeatureWeight`
      und `FeatureHistory` ergänzt, App-Struktur (`RootTabView`, 4 Tabs) statt der veralteten
      Onboarding/Dashboard-Weiche-Beschreibung, Intro von „Ein-Screen-Prinzip" auf die vier Tabs korrigiert.
- [x] Alten `TODO.md`-Widerspruch zu „Gewicht" aufgelöst: „Gewicht" aus der Nicht-Ziele-Liste (Abschnitt
      „Explizit NICHT bauen") gestrichen, mit Hinweis-Absatz, dass der Redesign-Auftrag (`todo2.md`) den
      ursprünglichen MVP-Ausschluss bewusst aufgehoben hat. Alle anderen Nicht-Ziele gelten unverändert fort.
- [x] Finaler Durchlauf: kein physisches Gerät in dieser Umgebung verfügbar (siehe README-Abschnitt „Bekannte
      Grenzen dieser Umgebung" – Scanner/Widget waren schon in der MVP-Phase nur auf echtem Gerät verifizierbar).
      Stattdessen vollständiger Simulator-Durchlauf: Build + alle 90 Package-Tests + 2 XCUITests grün (Light Mode),
      zusätzlich gezielte Screenshot-Verifikation in Dark Mode und bei XXL Dynamic Type für die in Phase 6 neu
      hinzugekommenen Screens. Vor einem echten Release weiterhin auf echtem Gerät gegenprüfen (Ring, Scanner,
      Widget, Tabs) – wie schon für die MVP-Phase dokumentiert.
      Commit `chore(phase7): Politur & Konsistenz`.

---

## Prioritäten (falls Zeit knapp)

1. **Phase 1** (Rename) – schnell, entkoppelt.
2. **Phase 3 + 4** (mehrfarbiger Ring + zentriertes Dashboard) – der sichtbarste „Wow"-Effekt, Kern des Auftrags.
3. **Phase 2 + 5** (TabView + Gewichts-Tab) – größter Funktionszuwachs.
4. **Phase 6 + 7** (Unterseiten + Politur).

## Nicht-Ziele (Scope-Schutz bleibt)

Community, Rezepte, Mahlzeitenplanung, KI-Coach, Gamification, HealthKit-Sync, Trainings-/Kalorienverbrauch,
CloudKit-Sync (Readiness ja, Aktivierung nein) bleiben außen vor. Gewicht ist ab jetzt **in** Scope, der Rest nicht.
