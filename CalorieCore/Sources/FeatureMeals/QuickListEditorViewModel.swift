import DesignSystem
import Domain
import Foundation

/// Bearbeitet die Schnellauswahl (`QuickList`): Reihenfolge (Drag&Drop), Ordner (max. 1 Ebene),
/// Hinzufügen von Gerichten und Lebensmitteln. Jede Änderung wird sofort persistiert, damit die
/// spätere Sync-Schicht (9.3) immer den aktuellen Stand spiegelt.
@Observable
@MainActor
public final class QuickListEditorViewModel: FoodSearchProviding {
    public private(set) var quickList: QuickList = .empty
    public private(set) var templates: [MealTemplate] = []
    public private(set) var searchState: ViewState<[Food]> = .empty
    public private(set) var isLoaded = false

    private let quickListRepository: any QuickListRepository
    private let mealTemplateRepository: any MealTemplateRepository
    private let searchFoods: SearchFoodsUseCase
    private let buildItem = BuildMealTemplateItemUseCase()

    public init(
        quickListRepository: any QuickListRepository,
        mealTemplateRepository: any MealTemplateRepository,
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource
    ) {
        self.quickListRepository = quickListRepository
        self.mealTemplateRepository = mealTemplateRepository
        searchFoods = SearchFoodsUseCase(foodCatalogRepository: foodCatalogRepository, foodDataSource: foodDataSource)
    }

    public func load() async {
        quickList = await (try? quickListRepository.load()) ?? .empty
        templates = await (try? mealTemplateRepository.all()) ?? []
        isLoaded = true
    }

    // MARK: - Anzeige

    public func displayName(for leaf: QuickListLeaf) -> String {
        switch leaf {
        case let .meal(_, templateID):
            templates.first { $0.id == templateID }?.name ?? "Gericht"
        case let .food(_, item):
            item.foodName
        }
    }

    public func kcal(for leaf: QuickListLeaf) -> Double {
        switch leaf {
        case let .meal(_, templateID):
            templates.first { $0.id == templateID }?.totalKcal ?? 0
        case let .food(_, item):
            item.kcal
        }
    }

    public func isMeal(_ leaf: QuickListLeaf) -> Bool {
        if case .meal = leaf {
            return true
        }
        return false
    }

    // MARK: - Mutationen (jeweils sofort persistiert)

    public func moveTopLevel(from source: IndexSet, to destination: Int) async {
        quickList.entries.move(fromOffsets: source, toOffset: destination)
        await persist()
    }

    public func addMeal(templateID: UUID) async {
        quickList.entries.append(.leaf(.meal(id: UUID(), templateID: templateID)))
        await persist()
    }

    public func addFood(_ food: Food, amountGrams: Double) async {
        guard let item = try? buildItem(food: food, amountGrams: amountGrams) else { return }
        quickList.entries.append(.leaf(.food(id: UUID(), item: item)))
        await persist()
    }

    public func createFolder(name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        quickList.entries.append(.folder(id: UUID(), name: trimmed, items: []))
        await persist()
    }

    public func renameFolder(id: UUID, to newName: String) async {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        quickList.entries = quickList.entries.map { entry in
            if case let .folder(folderID, _, items) = entry, folderID == id {
                return .folder(id: folderID, name: trimmed, items: items)
            }
            return entry
        }
        await persist()
    }

    /// Entfernt einen Eintrag – ob Top-Level (Blatt oder Ordner) oder ein Blatt in einem Ordner.
    public func delete(entryID: UUID) async {
        var entries = quickList.entries
        entries.removeAll { $0.id == entryID }
        entries = entries.map { entry in
            if case let .folder(folderID, name, items) = entry {
                return .folder(id: folderID, name: name, items: items.filter { $0.id != entryID })
            }
            return entry
        }
        quickList.entries = entries
        await persist()
    }

    /// Verschiebt ein Blatt in einen Ordner (`folderID`) oder zurück auf die oberste Ebene (`nil`).
    public func moveLeaf(_ leafID: UUID, toFolder folderID: UUID?) async {
        guard let leaf = extractLeaf(leafID) else { return }
        if let folderID {
            quickList.entries = quickList.entries.map { entry in
                if case let .folder(fid, name, items) = entry, fid == folderID {
                    return .folder(id: fid, name: name, items: items + [leaf])
                }
                return entry
            }
        } else {
            quickList.entries.append(.leaf(leaf))
        }
        await persist()
    }

    /// Entfernt ein Blatt aus der Struktur (Top-Level oder Ordner) und gibt es zurück.
    private func extractLeaf(_ leafID: UUID) -> QuickListLeaf? {
        var found: QuickListLeaf?
        var entries: [QuickListEntry] = []
        for entry in quickList.entries {
            switch entry {
            case let .leaf(leaf) where leaf.id == leafID:
                found = leaf
            case let .folder(fid, name, items):
                if let hit = items.first(where: { $0.id == leafID }) {
                    found = hit
                    entries.append(.folder(id: fid, name: name, items: items.filter { $0.id != leafID }))
                } else {
                    entries.append(entry)
                }
            default:
                entries.append(entry)
            }
        }
        quickList.entries = entries
        return found
    }

    // MARK: - Suche (zum Hinzufügen von Lebensmitteln)

    public func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchState = .empty
            return
        }
        searchState = .loading
        let results = await searchFoods(query: query)
        searchState = results.isEmpty ? .empty : .loaded(results)
    }

    private func persist() async {
        try? await quickListRepository.save(quickList)
    }
}
