/// Tagesziele. `isCustomized == false` bedeutet: Auto-Vorschlag (30/40/30) aktiv.
public struct MacroGoals: Equatable, Sendable {
    public var dailyKcal: Int
    public var proteinGrams: Int
    public var carbsGrams: Int
    public var fatGrams: Int
    public var isCustomized: Bool

    public init(
        dailyKcal: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
        isCustomized: Bool
    ) {
        self.dailyKcal = dailyKcal
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.isCustomized = isCustomized
    }
}
