/// Aggregierte Ist-Werte eines Tages inkl. der zum Zeitpunkt gültigen Ziele.
public struct DayTotals: Equatable, Sendable {
    public var dayKey: String
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var goals: MacroGoals

    public init(
        dayKey: String,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        goals: MacroGoals
    ) {
        self.dayKey = dayKey
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.goals = goals
    }

    /// Die eine Zahl, die zählt. Kann negativ werden (Ziel überschritten).
    public var remainingKcal: Double {
        Double(goals.dailyKcal) - kcal
    }
}
