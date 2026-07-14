import Foundation

/// Ein Bestandteil eines `MealTemplate` – trägt einen denormalisierten Nährwert-Snapshot,
/// damit ein Gericht stabil bleibt, auch wenn sich der Katalog-`Food` später ändert
/// (gleiche Philosophie wie `DiaryEntry`). `foodID` ist nur eine lose Referenz.
public struct MealTemplateItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var foodID: UUID?
    public var foodName: String
    public var amountGrams: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double

    public init(
        id: UUID = UUID(),
        foodID: UUID? = nil,
        foodName: String,
        amountGrams: Double,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.id = id
        self.foodID = foodID
        self.foodName = foodName
        self.amountGrams = amountGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

/// Ein benanntes „Gericht" – eine wiederverwendbare Zusammenstellung mehrerer Lebensmittel
/// (z. B. „Standard-Frühstück"). Nährwerte sind die Summe der Items.
public struct MealTemplate: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    /// Optionaler Vorschlag für den Mahlzeitentyp beim Loggen (nil ⇒ aus Uhrzeit ableiten).
    public var mealType: MealType?
    public var items: [MealTemplateItem]

    public init(id: UUID = UUID(), name: String, mealType: MealType? = nil, items: [MealTemplateItem] = []) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.items = items
    }

    public var totalKcal: Double {
        items.reduce(0) { $0 + $1.kcal }
    }

    public var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }

    public var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbs }
    }

    public var totalFat: Double {
        items.reduce(0) { $0 + $1.fat }
    }
}
