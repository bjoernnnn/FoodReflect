import Foundation
import Testing
@testable import DesignSystem
@testable import Domain
@testable import FeatureDashboard

@Suite("DashboardViewModel")
@MainActor
struct DashboardViewModelTests {
    private let goals = MacroGoals(dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false)
    private let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func todayKey(_ date: Date = Date()) -> String {
        DayKey.make(for: date, calendar: fixedCalendar)
    }

    @Test("Lädt heutige Einträge und aggregierte Totals, andere Tage bleiben außen vor")
    func loadsTodayOnly() async {
        let today = todayKey()
        let entryToday = DiaryEntry(
            consumedAt: Date(),
            dayKey: today,
            foodName: "Apfel",
            amountGrams: 100,
            kcal: 300,
            protein: 1,
            carbs: 2,
            fat: 3
        )
        let entryYesterday = DiaryEntry(
            consumedAt: Date().addingTimeInterval(-86400), dayKey: "1999-01-01", foodName: "Alt", amountGrams: 1, kcal: 999,
            protein: 0, carbs: 0, fat: 0
        )
        let diaryRepository = FakeDiaryRepository(entries: [entryToday, entryYesterday])
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository,
            widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar
        )

        await sut.load()

        #expect(sut.todayEntries.count == 1)
        #expect(sut.todayEntries.first?.foodName == "Apfel")
        guard case let .loaded(totals) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(totals.kcal == 300)
        #expect(totals.remainingKcal == 1700)
    }

    @Test("Löschen entfernt den Eintrag und lädt neu")
    func deleteReloadsState() async {
        let today = todayKey()
        let entry = DiaryEntry(
            consumedAt: Date(),
            dayKey: today,
            foodName: "Apfel",
            amountGrams: 100,
            kcal: 300,
            protein: 1,
            carbs: 2,
            fat: 3
        )
        let diaryRepository = FakeDiaryRepository(entries: [entry])
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let widgetRefreshing = FakeWidgetRefreshing()
        let sut = DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository,
            widgetRefreshing: widgetRefreshing, calendar: fixedCalendar
        )
        await sut.load()

        await sut.delete(entryID: entry.id)

        #expect(sut.todayEntries.isEmpty)
        #expect(widgetRefreshing.reloadCount == 1)
        guard case let .loaded(totals) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(totals.kcal == 0)
    }

    @Test("Leerer Tag ohne Einträge crasht nicht und zeigt Nullsumme")
    func emptyDay() async {
        let diaryRepository = FakeDiaryRepository()
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository,
            widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar
        )

        await sut.load()

        #expect(sut.todayEntries.isEmpty)
        guard case let .loaded(totals) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(totals.kcal == 0)
        #expect(totals.remainingKcal == 2000)
    }

    @Test("Lädt Wochenstatistik über die letzten 7 Tage")
    func loadsWeekStats() async {
        let today = todayKey()
        let entry = DiaryEntry(
            consumedAt: Date(),
            dayKey: today,
            foodName: "Apfel",
            amountGrams: 100,
            kcal: 300,
            protein: 1,
            carbs: 2,
            fat: 3
        )
        let diaryRepository = FakeDiaryRepository(entries: [entry])
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository,
            widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar
        )

        await sut.load()

        #expect(sut.weekStats?.days.count == 7)
        #expect(sut.weekStats?.days.last?.dayKey == today)
    }

    @Test("Repository-Fehler beim Laden ergibt .error statt Crash")
    func loadFailureSurfacesErrorState() async {
        let diaryRepository = FakeDiaryRepository()
        diaryRepository.shouldThrow = true
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DashboardViewModel(
            diaryRepository: diaryRepository, goalsRepository: goalsRepository,
            widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar
        )

        await sut.load()

        guard case .error = sut.state else {
            Issue.record("expected .error, got \(sut.state)")
            return
        }
    }
}
