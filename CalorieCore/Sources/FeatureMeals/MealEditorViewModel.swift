import DesignSystem
import Domain
import Foundation

/// Erstellt oder bearbeitet ein Gericht (`MealTemplate`): Name, optionaler Mahlzeitentyp und
/// eine Zusammenstellung von Lebensmitteln (Suche → Menge → Item mit fixiertem Snapshot).
@Observable
@MainActor
public final class MealEditorViewModel: FoodSearchProviding {
    public var name: String
    public var mealType: MealType?
    public private(set) var items: [MealTemplateItem]
    public private(set) var searchState: ViewState<[Food]> = .empty
    public private(set) var isSaving = false

    private let templateID: UUID
    private let repository: any MealTemplateRepository
    private let searchFoods: SearchFoodsUseCase
    private let buildItem = BuildMealTemplateItemUseCase()

    /// `existing == nil` → neues Gericht; sonst Bearbeiten (ID bleibt erhalten).
    public init(
        existing: MealTemplate? = nil,
        repository: any MealTemplateRepository,
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource
    ) {
        templateID = existing?.id ?? UUID()
        name = existing?.name ?? ""
        mealType = existing?.mealType
        items = existing?.items ?? []
        self.repository = repository
        searchFoods = SearchFoodsUseCase(foodCatalogRepository: foodCatalogRepository, foodDataSource: foodDataSource)
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

    public var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    public func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchState = .empty
            return
        }
        searchState = .loading
        let results = await searchFoods(query: query)
        searchState = results.isEmpty ? .empty : .loaded(results)
    }

    /// Fügt ein Lebensmittel mit der gewählten Menge als fixiertes Item hinzu.
    public func addFood(_ food: Food, amountGrams: Double) {
        guard let item = try? buildItem(food: food, amountGrams: amountGrams) else { return }
        items.append(item)
    }

    public func removeItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    @discardableResult
    public func save() async -> Bool {
        guard canSave else { return false }
        isSaving = true
        defer { isSaving = false }
        let template = MealTemplate(
            id: templateID,
            name: name.trimmingCharacters(in: .whitespaces),
            mealType: mealType,
            items: items
        )
        do {
            try await repository.save(template)
            return true
        } catch {
            return false
        }
    }
}
