import Foundation

/// Berechnet aus einer Menge (Gramm) und den per-100g-Werten eines `Food` den
/// denormalisierten Snapshot für den Tagebucheintrag. Rechnet niemals live aus
/// `Food` – der Snapshot ist ab Erstellung unveränderlich gegenüber späteren
/// Food-Edits.
public struct LogFoodUseCase: Sendable {
    public init() {}

    /// `mealType == nil` leitet den Typ aus `consumedAt` ab (siehe `MealType.make`); ein explizit
    /// übergebener Wert (z. B. aus dem Segmented Control im Log-Sheet) hat Vorrang.
    public func callAsFunction(
        food: Food,
        amountGrams: Double,
        consumedAt: Date = Date(),
        mealType: MealType? = nil,
        calendar: Calendar = .current
    ) throws(DomainError) -> DiaryEntry {
        guard amountGrams >= 0 else { throw DomainError.invalidAmount }
        let factor = amountGrams / 100

        return DiaryEntry(
            consumedAt: consumedAt,
            dayKey: DayKey.make(for: consumedAt, calendar: calendar),
            foodName: food.name,
            amountGrams: amountGrams,
            kcal: (food.kcalPer100g * factor).rounded(),
            protein: Self.rounded1(food.proteinPer100g * factor),
            carbs: Self.rounded1(food.carbsPer100g * factor),
            fat: Self.rounded1(food.fatPer100g * factor),
            foodID: food.id,
            mealType: mealType ?? MealType.make(for: consumedAt, calendar: calendar)
        )
    }

    private static func rounded1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
