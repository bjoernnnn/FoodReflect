import Foundation

/// Tagebucheintrag – denormalisierter Snapshot der Nährwerte zum Erfassungszeitpunkt.
/// Späteres Editieren des zugrundeliegenden `Food` darf die Historie NICHT verändern.
public struct DiaryEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var consumedAt: Date
    public var dayKey: String
    public var foodName: String
    public var amountGrams: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double
    public var foodID: UUID?
    public var mealType: MealType

    public init(
        id: UUID = UUID(),
        consumedAt: Date,
        dayKey: String,
        foodName: String,
        amountGrams: Double,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        foodID: UUID? = nil,
        mealType: MealType = .snack
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
        self.mealType = mealType
    }
}
