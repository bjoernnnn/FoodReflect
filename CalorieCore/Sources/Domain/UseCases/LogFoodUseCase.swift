import Foundation

/// Berechnet aus einer Menge (Gramm) und den per-100g-Werten eines `Food` den
/// denormalisierten Snapshot für den Tagebucheintrag. Rechnet niemals live aus
/// `Food` – der Snapshot ist ab Erstellung unveränderlich gegenüber späteren
/// Food-Edits.
public struct LogFoodUseCase: Sendable {
    public init() {}

    public func callAsFunction(
        food: Food,
        amountGrams: Double,
        consumedAt: Date = Date(),
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
            foodID: food.id
        )
    }

    private static func rounded1(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }
}
