import Testing
@testable import Domain

@Suite("GetWeekStatsUseCase")
struct GetWeekStatsUseCaseTests {
    private let goals = MacroGoals(
        dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false
    )

    private func day(_ kcal: Double) -> DayTotals {
        DayTotals(dayKey: "d", kcal: kcal, protein: 0, carbs: 0, fat: 0, goals: goals)
    }

    @Test("Durchschnitt und Abweichung über 7 Tage")
    func averageAndDelta() {
        let days = [1800, 2200, 2000, 1900, 2100, 1800, 2400].map(day)
        let stats = GetWeekStatsUseCase.aggregate(days: days)
        #expect(abs(stats.averageKcal - 14200.0 / 7.0) < 0.0001)
        #expect(stats.deltaFromGoal > 0) // im Schnitt über Ziel
    }

    @Test("Leere Woche liefert 0/0 statt Division durch 0")
    func emptyWeek() {
        let stats = GetWeekStatsUseCase.aggregate(days: [])
        #expect(stats.averageKcal == 0)
        #expect(stats.deltaFromGoal == 0)
        #expect(stats.days.isEmpty)
    }

    @Test("Konstant unter Ziel ergibt negatives Delta")
    func underGoal() {
        let days = Array(repeating: day(1500), count: 7)
        let stats = GetWeekStatsUseCase.aggregate(days: days)
        #expect(stats.averageKcal == 1500)
        #expect(stats.deltaFromGoal == -500)
    }
}
