import Domain
import Foundation

final class FakeMealTemplateRepository: MealTemplateRepository, @unchecked Sendable {
    private(set) var storage: [MealTemplate]
    var shouldThrow = false

    init(templates: [MealTemplate] = []) {
        storage = templates
    }

    func all() async throws(DomainError) -> [MealTemplate] {
        if shouldThrow {
            throw DomainError.offline
        }
        return storage
    }

    func template(id: UUID) async throws(DomainError) -> MealTemplate? {
        storage.first { $0.id == id }
    }

    func save(_ template: MealTemplate) async throws(DomainError) {
        if shouldThrow {
            throw DomainError.offline
        }
        storage.removeAll { $0.id == template.id }
        storage.append(template)
    }

    func delete(id: UUID) async throws(DomainError) {
        if shouldThrow {
            throw DomainError.offline
        }
        storage.removeAll { $0.id == id }
    }
}

final class FakeQuickListRepository: QuickListRepository, @unchecked Sendable {
    private(set) var stored: QuickList
    private(set) var saveCount = 0

    init(quickList: QuickList = .empty) {
        stored = quickList
    }

    func load() async throws(DomainError) -> QuickList {
        stored
    }

    func save(_ quickList: QuickList) async throws(DomainError) {
        stored = quickList
        saveCount += 1
    }
}

final class FakeFoodCatalogRepository: FoodCatalogRepository, @unchecked Sendable {
    var localResults: [Food] = []

    func food(barcode: String) async throws(DomainError) -> Food? {
        localResults.first { $0.barcode == barcode }
    }

    func search(localQuery query: String) async throws(DomainError) -> [Food] {
        localResults.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func save(_: Food) async throws(DomainError) {}

    func recordUsage(foodID _: UUID, at _: Date) async throws(DomainError) {}
}

final class FakeFoodDataSource: FoodDataSource, @unchecked Sendable {
    var remoteResults: [Food] = []

    func fetchProduct(barcode: String) async throws(DomainError) -> Food? {
        remoteResults.first { $0.barcode == barcode }
    }

    func search(query: String) async throws(DomainError) -> [Food] {
        remoteResults.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

enum TestFood {
    static func make(name: String, kcalPer100g: Double = 100) -> Food {
        Food(
            name: name,
            kcalPer100g: kcalPer100g,
            proteinPer100g: 10,
            carbsPer100g: 20,
            fatPer100g: 5,
            servingSizeGrams: 100,
            source: .manual
        )
    }
}
