import Foundation

/// Katalog-Eintrag (Cache aus Open Food Facts oder manuell erfasst).
/// Nährwerte werden IMMER pro 100 g/ml normalisiert gespeichert.
public struct Food: Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var brand: String?
    public var barcode: String?
    public var kcalPer100g: Double
    public var proteinPer100g: Double
    public var carbsPer100g: Double
    public var fatPer100g: Double
    public var servingSizeGrams: Double?
    public var source: FoodSource
    public var lastUsedAt: Date?
    public var useCount: Int

    public init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        kcalPer100g: Double,
        proteinPer100g: Double,
        carbsPer100g: Double,
        fatPer100g: Double,
        servingSizeGrams: Double? = nil,
        source: FoodSource,
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
        self.source = source
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
    }
}
