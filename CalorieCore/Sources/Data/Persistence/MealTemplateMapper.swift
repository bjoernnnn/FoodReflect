import Domain
import Foundation

enum MealTemplateMapper {
    static func toDomain(_ model: SDMealTemplate) -> MealTemplate {
        let items = (try? JSONDecoder().decode([MealTemplateItem].self, from: model.itemsData)) ?? []
        return MealTemplate(
            id: model.id,
            name: model.name,
            mealType: MealType(rawValue: model.mealTypeRaw),
            items: items
        )
    }

    static func toModel(_ template: MealTemplate) -> SDMealTemplate {
        SDMealTemplate(
            id: template.id,
            name: template.name,
            mealTypeRaw: template.mealType?.rawValue ?? "",
            itemsData: encodedItems(template.items)
        )
    }

    /// Für das Upsert bestehender Zeilen (In-Place-Update statt Duplikat).
    static func apply(_ template: MealTemplate, to model: SDMealTemplate) {
        model.name = template.name
        model.mealTypeRaw = template.mealType?.rawValue ?? ""
        model.itemsData = encodedItems(template.items)
    }

    private static func encodedItems(_ items: [MealTemplateItem]) -> Data {
        (try? JSONEncoder().encode(items)) ?? Data()
    }
}
