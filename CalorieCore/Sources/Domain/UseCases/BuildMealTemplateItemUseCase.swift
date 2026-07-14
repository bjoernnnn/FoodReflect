import Foundation

/// Baut aus einem Katalog-`Food` + Menge einen `MealTemplateItem` mit fixiertem Nährwert-Snapshot.
/// Nutzt `LogFoodUseCase` als einzige Quelle der per-100g-Rechnung/Rundung, damit Gericht-Items
/// exakt so kalkulieren wie normale Tagebucheinträge.
public struct BuildMealTemplateItemUseCase: Sendable {
    private let logFood = LogFoodUseCase()

    public init() {}

    public func callAsFunction(food: Food, amountGrams: Double) throws(DomainError) -> MealTemplateItem {
        let entry = try logFood(food: food, amountGrams: amountGrams)
        return MealTemplateItem(
            foodID: food.id,
            foodName: entry.foodName,
            amountGrams: entry.amountGrams,
            kcal: entry.kcal,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat
        )
    }
}
