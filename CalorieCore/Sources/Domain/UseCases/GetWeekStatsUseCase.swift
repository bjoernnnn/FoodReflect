/// Wochenzusammenfassung: Ø kcal/Tag und Abweichung vom Ziel, über `GetDayTotalsUseCase` aggregiert.
public struct GetWeekStatsUseCase: Sendable {
    private let diaryRepository: DiaryRepository
    private let goalsRepository: GoalsRepository

    public init(diaryRepository: DiaryRepository, goalsRepository: GoalsRepository) {
        self.diaryRepository = diaryRepository
        self.goalsRepository = goalsRepository
    }

    public func callAsFunction(dayKeys: [String]) async throws(DomainError) -> WeekStats {
        guard let firstDayKey = dayKeys.first, let lastDayKey = dayKeys.last else {
            return Self.aggregate(days: [])
        }
        let entries = try await diaryRepository.entries(fromDayKey: firstDayKey, toDayKey: lastDayKey)
        let goals = try await goalsRepository.currentGoals() ?? GetDayTotalsUseCase.noGoals
        let days = dayKeys.map { dayKey in
            GetDayTotalsUseCase.aggregate(dayKey: dayKey, entries: entries, goals: goals)
        }
        return Self.aggregate(days: days)
    }

    /// Reine Aggregationslogik, unabhängig von den Repositories testbar.
    public static func aggregate(days: [DayTotals]) -> WeekStats {
        guard !days.isEmpty else {
            return WeekStats(days: days, averageKcal: 0, deltaFromGoal: 0)
        }
        let totalKcal = days.reduce(0) { $0 + $1.kcal }
        let averageKcal = totalKcal / Double(days.count)
        let targetKcal = Double(days.last?.goals.dailyKcal ?? 0)
        return WeekStats(days: days, averageKcal: averageKcal, deltaFromGoal: averageKcal - targetKcal)
    }
}
