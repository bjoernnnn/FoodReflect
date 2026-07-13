import Testing
@testable import DesignSystem
@testable import Domain
@testable import FeatureSettings

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {
    @Test("Lädt bestehende Ziele")
    func loadsExistingGoals() async {
        let existing = MacroGoals(dailyKcal: 1800, proteinGrams: 135, carbsGrams: 180, fatGrams: 60, isCustomized: true)
        let repository = FakeGoalsRepository(goals: existing)
        let sut = SettingsViewModel(goalsRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        await sut.load()

        guard case let .loaded(goals) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(goals == existing)
    }

    @Test("Keine Ziele vorhanden ergibt .empty statt Crash")
    func noGoalsYieldsEmptyState() async {
        let repository = FakeGoalsRepository(goals: nil)
        let sut = SettingsViewModel(goalsRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        await sut.load()

        guard case .empty = sut.state else {
            Issue.record("expected .empty, got \(sut.state)")
            return
        }
    }

    @Test("Manuelles Speichern markiert die Ziele als customized")
    func manualSaveMarksCustomized() async {
        let repository = FakeGoalsRepository()
        let sut = SettingsViewModel(goalsRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        await sut.save(dailyKcal: 2200, proteinGrams: 160, carbsGrams: 220, fatGrams: 70)

        #expect(repository.goals?.isCustomized == true)
        #expect(repository.goals?.dailyKcal == 2200)
    }

    @Test("Auto-Vorschlag wiederherstellen setzt isCustomized zurück auf false")
    func restoreAutoSuggestionResetsCustomizedFlag() async {
        let repository = FakeGoalsRepository(
            goals: MacroGoals(dailyKcal: 2200, proteinGrams: 999, carbsGrams: 999, fatGrams: 999, isCustomized: true)
        )
        let sut = SettingsViewModel(goalsRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        await sut.restoreAutoSuggestion(dailyKcal: 2200)

        #expect(repository.goals?.isCustomized == false)
        #expect(repository.goals?.proteinGrams == 165) // 2200*0.30/4
    }
}
