import Foundation
import SwiftData

/// Denormalisierter Snapshot, append-only. `foodID` ist eine lose, optionale
/// Referenz (kein `@Relationship`) – CloudKit-konform und entkoppelt vom
/// Katalog-Lebenszyklus.
@Model
public final class SDDiaryEntry {
    public var id = UUID()
    public var consumedAt = Date()
    public var dayKey: String = ""
    public var foodName: String = ""
    public var amountGrams: Double = 0
    public var kcal: Double = 0
    public var protein: Double = 0
    public var carbs: Double = 0
    public var fat: Double = 0
    public var foodID: UUID?
    /// Roh-String des `MealType`. Default sorgt dafür, dass Bestandsdaten (vor Block A)
    /// beim Migrieren als Snack gelten, kein Nachtrag nötig.
    public var mealTypeRaw: String = "snack"

    public init(
        id: UUID = UUID(),
        consumedAt: Date = Date(),
        dayKey: String = "",
        foodName: String = "",
        amountGrams: Double = 0,
        kcal: Double = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        foodID: UUID? = nil,
        mealTypeRaw: String = "snack"
    ) {
        self.id = id
        self.consumedAt = consumedAt
        self.dayKey = dayKey
        self.foodName = foodName
        self.amountGrams = amountGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.foodID = foodID
        self.mealTypeRaw = mealTypeRaw
    }
}
