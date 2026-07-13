/// 30 % Protein / 40 % Kohlenhydrate / 30 % Fett, umgerechnet aus dem Tagesziel-kcal.
public struct SuggestMacrosUseCase: Sendable {
    public init() {}

    public func callAsFunction(dailyKcal: Int) -> MacroGoals {
        let kcal = Double(max(dailyKcal, 0))
        let proteinGrams = (kcal * 0.30 / 4).rounded()
        let carbsGrams = (kcal * 0.40 / 4).rounded()
        let fatGrams = (kcal * 0.30 / 9).rounded()
        return MacroGoals(
            dailyKcal: dailyKcal,
            proteinGrams: Int(proteinGrams),
            carbsGrams: Int(carbsGrams),
            fatGrams: Int(fatGrams),
            isCustomized: false
        )
    }
}
