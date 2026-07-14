import Foundation

/// Expandiert ein Gericht (`MealTemplate`) in N `DiaryEntry`-Snapshots für einen Tag.
/// Reine Funktion – die gespeicherten Item-Snapshots werden übernommen (kein Katalog-Lookup),
/// damit ein Gericht auch offline (z. B. via Watch-Event) stabil geloggt werden kann.
public struct LogMealTemplateUseCase: Sendable {
    public init() {}

    public func callAsFunction(
        template: MealTemplate,
        consumedAt: Date = Date(),
        mealType: MealType? = nil,
        calendar: Calendar = .current
    ) -> [DiaryEntry] {
        let dayKey = DayKey.make(for: consumedAt, calendar: calendar)
        let resolvedMeal = mealType ?? template.mealType ?? MealType.make(for: consumedAt, calendar: calendar)
        return template.items.map { item in
            DiaryEntry(
                consumedAt: consumedAt,
                dayKey: dayKey,
                foodName: item.foodName,
                amountGrams: item.amountGrams,
                kcal: item.kcal,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                foodID: item.foodID,
                mealType: resolvedMeal
            )
        }
    }
}
