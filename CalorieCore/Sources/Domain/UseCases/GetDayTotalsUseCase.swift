/// Summiert Tagebucheinträge eines Tages zu `DayTotals` mit den aktuell gültigen Zielen.
public struct GetDayTotalsUseCase: Sendable {
    private let diaryRepository: DiaryRepository
    private let goalsRepository: GoalsRepository

    public init(diaryRepository: DiaryRepository, goalsRepository: GoalsRepository) {
        self.diaryRepository = diaryRepository
        self.goalsRepository = goalsRepository
    }

    public func callAsFunction(dayKey: String) async throws(DomainError) -> DayTotals {
        let entries = try await diaryRepository.entries(on: dayKey)
        let goals = try await goalsRepository.currentGoals() ?? Self.noGoals
        return Self.aggregate(dayKey: dayKey, entries: entries, goals: goals)
    }

    /// Reine Aggregationslogik, unabhängig von den Repositories testbar.
    public static func aggregate(dayKey: String, entries: [DiaryEntry], goals: MacroGoals) -> DayTotals {
        let matching = entries.filter { $0.dayKey == dayKey }
        let kcal: Double = matching.reduce(0) { $0 + $1.kcal }
        let protein: Double = matching.reduce(0) { $0 + $1.protein }
        let carbs: Double = matching.reduce(0) { $0 + $1.carbs }
        let fat: Double = matching.reduce(0) { $0 + $1.fat }
        return DayTotals(dayKey: dayKey, kcal: kcal, protein: protein, carbs: carbs, fat: fat, goals: goals)
    }

    public static let noGoals = MacroGoals(dailyKcal: 0, proteinGrams: 0, carbsGrams: 0, fatGrams: 0, isCustomized: false)
}
