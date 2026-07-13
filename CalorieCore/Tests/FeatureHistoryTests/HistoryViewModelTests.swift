import Foundation
import Testing
@testable import Domain
@testable import FeatureHistory

@Suite("HistoryViewModel")
@MainActor
struct HistoryViewModelTests {
    private let goals = MacroGoals(dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false)
    private let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test("Lädt Wochenansicht mit 7 Tagen")
    func loadsWeek() async {
        let diaryRepository = FakeDiaryRepository()
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = HistoryViewModel(diaryRepository: diaryRepository, goalsRepository: goalsRepository, calendar: fixedCalendar)

        await sut.load(days: 7)

        guard case let .loaded(stats) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(stats.days.count == 7)
    }

    @Test("Lädt Monatsansicht mit 30 Tagen")
    func loadsMonth() async {
        let diaryRepository = FakeDiaryRepository()
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = HistoryViewModel(diaryRepository: diaryRepository, goalsRepository: goalsRepository, calendar: fixedCalendar)

        await sut.load(days: 30)

        guard case let .loaded(stats) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(stats.days.count == 30)
    }

    @Test("Repository-Fehler ergibt .error statt Crash")
    func loadFailureSurfacesErrorState() async {
        let diaryRepository = FakeDiaryRepository()
        diaryRepository.shouldThrow = true
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = HistoryViewModel(diaryRepository: diaryRepository, goalsRepository: goalsRepository, calendar: fixedCalendar)

        await sut.load(days: 7)

        guard case .error = sut.state else {
            Issue.record("expected .error, got \(sut.state)")
            return
        }
    }
}
