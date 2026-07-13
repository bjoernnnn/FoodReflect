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

## Phase 2 – Navigation auf TabView umstellen (Voraussetzung für Gewichts-Tab)

Das Ein-Screen-Prinzip wird zur **Tab-Navigation** erweitert. `RootView` bleibt die Weiche Onboarding↔App,
verdrahtet aber jetzt eine `RootTabView`. Composition Root bleibt der einzige Ort, der alle Features kennt.

- [ ] Neue View `App/RootTabView.swift` mit `TabView`:
  - Tab „Heute" → `DashboardView` (SF Symbol `flame.fill`)
  - Tab „Verlauf" → neue `HistoryView` (SF Symbol `chart.bar.fill`)
  - Tab „Gewicht" → neue `WeightView` (SF Symbol `scalemass.fill`)
  - Tab „Einstellungen" → `SettingsView` (SF Symbol `gearshape.fill`)
- [ ] `RootView.swift` (case `.true`) auf `RootTabView` umbauen; alle Repository-/Closure-Injektionen dorthin
      durchreichen (wie bisher pro Feature-View).
- [ ] Settings wandert aus der Dashboard-Toolbar in einen eigenen Tab → Zahnrad-Toolbar-Item im Dashboard entfernen
      (oder als Shortcut belassen – Entscheidung dokumentieren).
- [ ] Akzentfarbe für die TabBar setzen (`.tint(ColorToken.accent)`), damit aktive Tabs im Marken-Türkis erscheinen.
- [ ] UITest-Smoke: `FoodReflectUITests` um Tab-Wechsel-Assertions erweitern (Accessibility-Identifier je Tab).
- [ ] Build + Tests grün, Commit `feat(phase2): TabView-Navigation`.

---

## Phase 3 – Mehrfarbiger Makro-Ring (Kern des Redesigns)

Der einfarbige Rest-kcal-Ring wird durch einen **segmentierten Ring** ersetzt: jedes Makro bekommt seinen
Anteil an den konsumierten kcal als farbiges Segment. Das ist die zentrale „spannendere" Design-Änderung.

**Farbschema (zentral als Tokens definieren, nicht inline):**

- [ ] In `ColorToken.swift` Makro-Farben ergänzen (statt inline `.blue/.orange/.pink` überall):
  - `proteinColor` = Blau (z. B. `Color(red: 0.20, green: 0.55, blue: 0.95)`)
  - `carbsColor`   = Orange/Amber (z. B. `Color(red: 0.98, green: 0.62, blue: 0.09)`)
  - `fatColor`     = Pink/Magenta (z. B. `Color(red: 0.93, green: 0.31, blue: 0.55)`)
  - Danach `DashboardView` + `MacroBar`-Aufrufe auf diese Tokens umstellen (Single Source of Truth).

**Neue Komponente `SegmentedProgressRing`:**

- [ ] Neue Datei `CalorieCore/Sources/DesignSystem/Components/SegmentedProgressRing.swift`.
- [ ] API: nimmt Segmente als `[(value: Double, color: Color)]` + Gesamt-Referenzwert (kcal-Ziel) entgegen.
- [ ] Rendering: gestapelte `Circle().trim(from:to:)`-Bögen, jedes Segment beginnt am Ende des vorherigen
      (kumulative Start-/End-Winkel), `lineCap: .round`, `rotationEffect(-90°)`, sanfte `.easeInOut`-Animation
      auf Wertänderung.
- [ ] Rest-Bogen (noch nicht verbraucht) in `ColorToken.secondaryBackground` als Track darunter.
- [ ] Überschreitung des Ziels sichtbar machen (z. B. letzter Bogen in `ColorToken.warning`, wenn Summe > Ziel).
- [ ] `#Preview` mit Beispielwerten; sinnvoller `accessibilityLabel`/`accessibilityValue` (Ring bleibt sonst hidden).
- [ ] `ProgressRing` (alt) beibehalten für das Widget oder ebenfalls migrieren – im Widget mindestens die neuen
      Makro-Farben nutzen, damit App und Widget konsistent wirken.

**Ring-Zentrum:**

- [ ] In der Ring-Mitte weiterhin große Rest-kcal-Zahl (`@ScaledMetric`, `rounded`), darunter „kcal übrig".
- [ ] Kleine Makro-Legende (drei farbige Punkte + `P / K / F`-Kürzel) direkt unter dem Ring, zentriert.

---

## Phase 4 – Dashboard-Redesign: zentrieren & spannender machen

Der Hero-Bereich (Ring + Makros) wird optisch aufgewertet und **horizontal zentriert**. Weg von der reinen
List-Optik hin zu einem klaren, mittigen Fokus.

- [ ] Hero-Sektion (Ring + Legende + Makro-Balken) in einen zentrierten `VStack` mit `frame(maxWidth: .infinity)`
      und `multilineTextAlignment(.center)` setzen; nicht mehr linksbündig in der `List`-Row.
- [ ] Ring vergrößern (z. B. 220–240 pt) und mit dezentem Schatten/`.shadow` oder weichem Verlauf hinterlegen.
- [ ] Makro-Balken (`MacroBar`) unter dem Ring zentriert gruppieren, konsistent mit den neuen Makro-Farben;
      optional Prozent-Zielerreichung als kleine Zahl rechts.
- [ ] Sanfte Auftritts-Animation beim Laden (z. B. Ring-Trim animiert von 0 → Wert, `.transition`/`.animation`).
- [ ] Card-Optik vereinheitlichen: `cardBackground()` mit etwas mehr `cornerRadius` + leichter Schattierung
      (in `CardBackground.swift` zentral anpassen, damit alle Cards profitieren).
- [ ] „Heutige Einträge" bleibt als Liste darunter; leere Zeile freundlicher formulieren + kleines Symbol.
- [ ] Haptisches Feedback beim Erfassen/Löschen (`.sensoryFeedback`, iOS 17+) für mehr „Lebendigkeit".
- [ ] Dynamic Type & Dark Mode gegenprüfen (Ring-Zahl skaliert bereits via `@ScaledMetric`).
- [ ] Build + Tests grün, Commit `feat(phase4): Dashboard zentriert & mehrfarbiger Ring`.

---

## Phase 5 – Gewichts-Tracking (Domain → Data → Feature)

Eigener Tab nur fürs Gewicht. Sauber durch alle Schichten, damit CloudKit-Readiness (keine `@Attribute(.unique)`,
optionale Relationships, Defaults) erhalten bleibt.

**Domain:**

- [ ] Entity `CalorieCore/Sources/Domain/Entities/WeightEntry.swift`: `id: UUID`, `dayKey: String`,
      `weightKg: Double`, `recordedAt: Date`. `Equatable, Sendable`.
- [ ] Protokoll `CalorieCore/Sources/Domain/Repositories/WeightRepository.swift`:
      `entries(fromDayKey:toDayKey:)`, `latest()`, `save(_:)`, `delete(entryID:)` – jeweils `async throws(DomainError)`.
- [ ] Optional UseCase `GetWeightTrendUseCase` (gleitender Durchschnitt / Delta zur Vorwoche), analog zu `GetWeekStatsUseCase`.

**Data:**

- [ ] SwiftData-Modell `CalorieCore/Sources/Data/Persistence/SDWeightEntry.swift` (alle Properties mit Defaults, kein unique).
- [ ] `WeightEntryMapper.swift` (Domain ↔ SD), analog zu `DiaryEntryMapper`.
- [ ] `SwiftDataWeightRepository.swift` als `@ModelActor`, analog zu `SwiftDataDiaryRepository`.
- [ ] Modell in `ModelContainerFactory` (App-Group- **und** In-Memory-Schema) registrieren.

**Feature:**

- [ ] Neues Package-Target `FeatureWeight` in `CalorieCore/Package.swift` (Products + Target, `dependencies: Domain, DesignSystem`).
- [ ] `WeightViewModel.swift` (`@Observable`, `ViewState<[WeightEntry]>`), lädt Verlauf, speichert neuen Wert.
- [ ] `WeightView.swift`:
  - Oben große aktuelle Gewichtszahl (zentriert), darunter Delta zur letzten Messung (grün/rot).
  - **Swift-Charts-Verlaufskurve** (`LineMark` + `PointMark`) über wählbaren Zeitraum (Woche/Monat/Alle).
  - Sheet zum Eintragen (Zahl + Datum, Einheit kg; optional lb-Umschaltung in Settings – Post-MVP notieren).
  - Swipe-to-delete auf Einträge.
- [ ] Verdrahtung: `WeightRepository` in `AppContainer` erzeugen, per Init an `WeightView`/VM im `RootTabView` reichen.
- [ ] `project.yml`: App-Target-Dependency `FeatureWeight` ergänzen, `xcodegen generate`.
- [ ] Tests: `FeatureWeightTests` (VM mit In-Memory-Fake) + `SwiftDataWeightRepositoryTests` (In-Memory-SwiftData).
- [ ] Build + Tests grün, Commit `feat(phase5): Gewichts-Tab mit Verlaufskurve`.

---

## Phase 6 – Sinnvolle Unterseiten

Unterseiten, die den bestehenden Datenfluss ergänzen (jeweils per `NavigationStack`-Push innerhalb ihres Tabs).

- [ ] **Verlauf-Tab (`HistoryView`)**: Monats-/Wochenübersicht der kcal (Balken- + Durchschnittslinie), aus
      `GetWeekStatsUseCase` bzw. neuem `GetMonthStatsUseCase` (Erweiterung des Diary-Ranges). Der bisherige
      „Diese Woche"-Chart kann vom Dashboard hierher wandern (Dashboard bleibt fokussierter).
- [ ] **Tages-Detail (`DayDetailView`)**: Tippen auf einen Tag im Verlauf → alle Einträge dieses Tages,
      Makro-Aufschlüsselung, Zielerreichung. Nutzt `diaryRepository.entries(on:)`.
- [ ] **Eintrag-Detail (`EntryDetailView`)**: Tippen auf einen Eintrag im Dashboard → volle Nährwerte,
      Menge editieren, löschen. (Aktuell nur Swipe-Delete – Detail erhöht Nutzwert.)
- [ ] **Gewicht-Historie (`WeightHistoryView`)**: vollständige Tabelle aller Messungen mit Löschen/Bearbeiten,
      erreichbar aus dem Gewichts-Tab.
- [ ] **Über/Info in Settings**: Version, verwendete Datenquelle (Open Food Facts, ODbL-Lizenzhinweis),
      Datenschutz-Hinweis „alles lokal". (ODbL-Attribution ist ohnehin Pflicht.)
- [ ] Jede Unterseite: leerer/Fehler-Zustand via `ContentUnavailableView`, konsistent mit Dashboard.
- [ ] Build + Tests grün, Commit `feat(phase6): Unterseiten (Verlauf, Detail, Gewicht-Historie, Info)`.

---

## Phase 7 – Politur & Konsistenz

- [ ] Alle Makro-Farben kommen aus `ColorToken` (kein inline `.blue/.orange/.pink` mehr) – global prüfen.
- [ ] Widget an neue Farben/Namen angleichen (Konsistenz App ↔ Home-Screen).
- [ ] Animationen dezent halten (kein Overkill) – Ring-Trim, Tab-Wechsel, Sheet-Präsentation.
- [ ] Accessibility: VoiceOver-Labels für neuen Ring, Gewichtskurve, Tabs; Dynamic Type XXL testen.
- [ ] Dark Mode für alle neuen Views prüfen (Farben haben genug Kontrast auf `systemBackground`).
- [ ] `swiftlint lint` + `swiftformat .` sauber; README-Architekturbaum um `FeatureWeight` ergänzen.
- [ ] Alten `TODO.md`-Widerspruch zu „Gewicht" auflösen (siehe Analyse-Hinweis oben).
- [ ] Finaler Durchlauf auf echtem Gerät (Ring, Scanner, Widget, Tabs), Commit `chore(phase7): Politur & Konsistenz`.

---

## Prioritäten (falls Zeit knapp)

1. **Phase 1** (Rename) – schnell, entkoppelt.
2. **Phase 3 + 4** (mehrfarbiger Ring + zentriertes Dashboard) – der sichtbarste „Wow"-Effekt, Kern des Auftrags.
3. **Phase 2 + 5** (TabView + Gewichts-Tab) – größter Funktionszuwachs.
4. **Phase 6 + 7** (Unterseiten + Politur).

## Nicht-Ziele (Scope-Schutz bleibt)

Community, Rezepte, Mahlzeitenplanung, KI-Coach, Gamification, HealthKit-Sync, Trainings-/Kalorienverbrauch,
CloudKit-Sync (Readiness ja, Aktivierung nein) bleiben außen vor. Gewicht ist ab jetzt **in** Scope, der Rest nicht.
