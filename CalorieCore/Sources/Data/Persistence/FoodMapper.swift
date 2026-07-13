import Domain
import Foundation

enum FoodMapper {
    static func toDomain(_ model: SDFood) -> Food {
        Food(
            id: model.id,
            name: model.name,
            brand: model.brand,
            barcode: model.barcode,
            kcalPer100g: model.kcalPer100g,
            proteinPer100g: model.proteinPer100g,
            carbsPer100g: model.carbsPer100g,
            fatPer100g: model.fatPer100g,
            servingSizeGrams: model.servingSizeGrams,
            source: source(fromRawValue: model.sourceRawValue, code: model.openFoodFactsCode),
            lastUsedAt: model.lastUsedAt,
            useCount: model.useCount
        )
    }

    static func toModel(_ food: Food) -> SDFood {
        let model = SDFood(id: food.id)
        update(model, from: food)
        return model
    }

    static func update(_ model: SDFood, from food: Food) {
        model.name = food.name
        model.brand = food.brand
        model.barcode = food.barcode
        model.kcalPer100g = food.kcalPer100g
        model.proteinPer100g = food.proteinPer100g
        model.carbsPer100g = food.carbsPer100g
        model.fatPer100g = food.fatPer100g
        model.servingSizeGrams = food.servingSizeGrams
        model.lastUsedAt = food.lastUsedAt
        model.useCount = food.useCount

        switch food.source {
        case .manual:
            model.sourceRawValue = "manual"
            model.openFoodFactsCode = nil
        case let .openFoodFacts(code):
            model.sourceRawValue = "openFoodFacts"
            model.openFoodFactsCode = code
        }
    }

    private static func source(fromRawValue rawValue: String, code: String?) -> FoodSource {
        guard rawValue == "openFoodFacts", let code else { return .manual }
        return .openFoodFacts(code: code)
    }
}
