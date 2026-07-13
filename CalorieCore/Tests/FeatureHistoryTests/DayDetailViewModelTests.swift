import Foundation
import Testing
@testable import Domain
@testable import FeatureHistory

@Suite("DayDetailViewModel")
@MainActor
struct DayDetailViewModelTests {
    private let goals = MacroGoals(dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false)

    @Test("Lädt Einträge und aggregierte Totals für den angefragten Tag")
    func loadsDayEntriesAndTotals() async {
        let entry = DiaryEntry(
            consumedAt: Date(),
            dayKey: "2026-07-13",
            foodName: "Apfel",
            amountGrams: 100,
            kcal: 300,
            protein: 1,
            carbs: 2,
            fat: 3
        )
        let otherDayEntry = DiaryEntry(
            consumedAt: Date(), dayKey: "2026-07-12", foodName: "Alt", amountGrams: 1, kcal: 999,
            protein: 0, carbs: 0, fat: 0
        )
        let diaryRepository = FakeDiaryRepository(entries: [entry, otherDayEntry])
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DayDetailViewModel(dayKey: "2026-07-13", diaryRepository: diaryRepository, goalsRepository: goalsRepository)

        await sut.load()

        #expect(sut.entries.count == 1)
        guard case let .loaded(totals) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(totals.kcal == 300)
    }

    @Test("Tag ohne Einträge ergibt .empty statt Crash")
    func emptyDayYieldsEmpty() async {
        let diaryRepository = FakeDiaryRepository()
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DayDetailViewModel(dayKey: "2026-07-13", diaryRepository: diaryRepository, goalsRepository: goalsRepository)

        await sut.load()

        guard case .empty = sut.state else {
            Issue.record("expected .empty, got \(sut.state)")
            return
        }
    }

    @Test("Repository-Fehler ergibt .error statt Crash")
    func loadFailureSurfacesErrorState() async {
        let diaryRepository = FakeDiaryRepository()
        diaryRepository.shouldThrow = true
        let goalsRepository = FakeGoalsRepository(goals: goals)
        let sut = DayDetailViewModel(dayKey: "2026-07-13", diaryRepository: diaryRepository, goalsRepository: goalsRepository)

        await sut.load()

        guard case .error = sut.state else {
            Issue.record("expected .error, got \(sut.state)")
            return
        }
    }
}
