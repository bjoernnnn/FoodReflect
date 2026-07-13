import Foundation
import Testing
@testable import Domain

@Suite("GetDayTotalsUseCase")
struct GetDayTotalsUseCaseTests {
    private let goals = MacroGoals(
        dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false
    )

    private func entry(
        dayKey: String, kcal: Double, protein: Double = 0, carbs: Double = 0, fat: Double = 0
    ) -> DiaryEntry {
        DiaryEntry(
            consumedAt: Date(),
            dayKey: dayKey,
            foodName: "Test",
            amountGrams: 100,
            kcal: kcal,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
    }

    @Test("Summiert nur Einträge des angefragten Tages")
    func aggregatesOnlyMatchingDay() {
        let entries = [
            entry(dayKey: "2026-07-13", kcal: 300, protein: 20, carbs: 30, fat: 10),
            entry(dayKey: "2026-07-13", kcal: 200, protein: 10, carbs: 20, fat: 5),
            entry(dayKey: "2026-07-12", kcal: 1000) // anderer Tag, darf nicht zählen
        ]
        let totals = GetDayTotalsUseCase.aggregate(dayKey: "2026-07-13", entries: entries, goals: goals)
        #expect(totals.kcal == 500)
        #expect(totals.protein == 30)
        #expect(totals.carbs == 50)
        #expect(totals.fat == 15)
        #expect(totals.remainingKcal == 1500)
    }

    @Test("Tag ohne Einträge liefert Nullsumme, keine Division durch 0 o.ä.")
    func emptyDay() {
        let totals = GetDayTotalsUseCase.aggregate(dayKey: "2026-07-13", entries: [], goals: goals)
        #expect(totals.kcal == 0)
        #expect(totals.remainingKcal == 2000)
    }

    @Test("Ziel 0 kcal: remainingKcal kann negativ werden, kein Crash")
    func zeroGoal() {
        let zeroGoals = MacroGoals(dailyKcal: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0, isCustomized: false)
        let totals = GetDayTotalsUseCase.aggregate(
            dayKey: "2026-07-13",
            entries: [entry(dayKey: "2026-07-13", kcal: 300)],
            goals: zeroGoals
        )
        #expect(totals.remainingKcal == -300)
    }

    @Test("Über Repositories: fehlende Ziele fallen auf Null-Goals zurück")
    func missingGoalsFallBackToZero() async throws {
        let diary = InMemoryDiaryRepository(entries: [entry(dayKey: "2026-07-13", kcal: 400)])
        let goalsRepo = InMemoryGoalsRepository(goals: nil)
        let sut = GetDayTotalsUseCase(diaryRepository: diary, goalsRepository: goalsRepo)
        let totals = try await sut(dayKey: "2026-07-13")
        #expect(totals.kcal == 400)
        #expect(totals.goals.dailyKcal == 0)
    }
}
