import Domain
import Foundation

enum DiaryEntryMapper {
    static func toDomain(_ model: SDDiaryEntry) -> DiaryEntry {
        DiaryEntry(
            id: model.id,
            consumedAt: model.consumedAt,
            dayKey: model.dayKey,
            foodName: model.foodName,
            amountGrams: model.amountGrams,
            kcal: model.kcal,
            protein: model.protein,
            carbs: model.carbs,
            fat: model.fat,
            foodID: model.foodID,
            // Unbekannte/kaputte Rohwerte fallen sicher auf .snack zurück statt zu crashen.
            mealType: MealType(rawValue: model.mealTypeRaw) ?? .snack
        )
    }

    static func toModel(_ entry: DiaryEntry) -> SDDiaryEntry {
        SDDiaryEntry(
            id: entry.id,
            consumedAt: entry.consumedAt,
            dayKey: entry.dayKey,
            foodName: entry.foodName,
            amountGrams: entry.amountGrams,
            kcal: entry.kcal,
            protein: entry.protein,
            carbs: entry.carbs,
            fat: entry.fat,
            foodID: entry.foodID,
            mealTypeRaw: entry.mealType.rawValue
        )
    }
}
