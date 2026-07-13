import Foundation
import SwiftData

/// CloudKit-kompatibel: keine `@Attribute(.unique)`, alle Properties mit Defaults.
/// `sourceRawValue`/`openFoodFactsCode` bilden `FoodSource` flach ab (SwiftData
/// unterstützt keine Enums mit Associated Values direkt als gespeicherte Properties).
@Model
public final class SDFood {
    public var id: UUID = UUID()
    public var name: String = ""
    public var brand: String?
    public var barcode: String?
    public var kcalPer100g: Double = 0
    public var proteinPer100g: Double = 0
    public var carbsPer100g: Double = 0
    public var fatPer100g: Double = 0
    public var servingSizeGrams: Double?
    public var sourceRawValue: String = "manual"
    public var openFoodFactsCode: String?
    public var lastUsedAt: Date?
    public var useCount: Int = 0

    public init(
        id: UUID = UUID(),
        name: String = "",
        brand: String? = nil,
        barcode: String? = nil,
        kcalPer100g: Double = 0,
        proteinPer100g: Double = 0,
        carbsPer100g: Double = 0,
        fatPer100g: Double = 0,
        servingSizeGrams: Double? = nil,
        sourceRawValue: String = "manual",
        openFoodFactsCode: String? = nil,
        lastUsedAt: Date? = nil,
        useCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.kcalPer100g = kcalPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.servingSizeGrams = servingSizeGrams
        self.sourceRawValue = sourceRawValue
        self.openFoodFactsCode = openFoodFactsCode
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
