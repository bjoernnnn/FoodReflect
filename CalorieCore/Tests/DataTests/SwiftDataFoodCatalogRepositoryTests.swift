import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataFoodCatalogRepository")
struct SwiftDataFoodCatalogRepositoryTests {
    private func makeSUT() throws -> SwiftDataFoodCatalogRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataFoodCatalogRepository(modelContainer: container)
    }

    private func nutella() -> Food {
        Food(
            name: "Nutella",
            brand: "Ferrero",
            barcode: "3017620422003",
            kcalPer100g: 539,
            proteinPer100g: 6.3,
            carbsPer100g: 57.5,
            fatPer100g: 30.9,
            source: .openFoodFacts(code: "3017620422003")
        )
    }

    @Test("Speichern und Barcode-Lookup liefert denselben Eintrag inkl. Quelle")
    func saveAndLookupByBarcode() async throws {
        let sut = try makeSUT()
        let food = nutella()
        try await sut.save(food)

        let found = try await sut.food(barcode: "3017620422003")
        #expect(found?.id == food.id)
        #expect(found?.source == .openFoodFacts(code: "3017620422003"))
    }

    @Test("Unbekannter Barcode liefert nil, kein Fehler")
    func unknownBarcode() async throws {
        let sut = try makeSUT()
        let found = try await sut.food(barcode: "0000000000000")
        #expect(found == nil)
    }

    @Test("Suche ist case-insensitive und findet Teiltreffer in Name und Marke")
    func searchIsCaseInsensitive() async throws {
        let sut = try makeSUT()
        try await sut.save(nutella())

        let byName = try await sut.search(localQuery: "nutel")
        let byBrand = try await sut.search(localQuery: "FERRERO")
        #expect(byName.count == 1)
        #expect(byBrand.count == 1)
    }

    @Test("recordUsage erhöht useCount und setzt lastUsedAt")
    func recordUsageUpdatesMetadata() async throws {
        let sut = try makeSUT()
        let food = nutella()
        try await sut.save(food)
        let date = Date(timeIntervalSince1970: 1_752_364_800)

        try await sut.recordUsage(foodID: food.id, at: date)

        let found = try await sut.food(barcode: "3017620422003")
        #expect(found?.useCount == 1)
        #expect(found?.lastUsedAt == date)
    }

    @Test("recordUsage für unbekannte ID wirft DomainError.notFound")
    func recordUsageUnknownIDThrows() async throws {
        let sut = try makeSUT()
        await #expect(throws: DomainError.notFound) {
            try await sut.recordUsage(foodID: UUID(), at: Date())
        }
    }
}
