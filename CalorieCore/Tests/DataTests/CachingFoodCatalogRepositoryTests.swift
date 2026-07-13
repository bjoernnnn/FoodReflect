import Foundation
import Testing
@testable import Data
@testable import Domain

private final class FakeFoodCatalogRepository: FoodCatalogRepository, @unchecked Sendable {
    var stored: [Food] = []
    private(set) var savedFoods: [Food] = []

    func food(barcode: String) async throws(DomainError) -> Food? {
        stored.first { $0.barcode == barcode }
    }

    func search(localQuery query: String) async throws(DomainError) -> [Food] {
        stored.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func save(_ food: Food) async throws(DomainError) {
        savedFoods.append(food)
        stored.append(food)
    }

    func recordUsage(foodID _: UUID, at _: Date) async throws(DomainError) {}
}

private final class FakeFoodDataSource: FoodDataSource, @unchecked Sendable {
    var product: Food?
    private(set) var fetchCallCount = 0

    func fetchProduct(barcode _: String) async throws(DomainError) -> Food? {
        fetchCallCount += 1
        return product
    }

    func search(query _: String) async throws(DomainError) -> [Food] {
        []
    }
}

@Suite("CachingFoodCatalogRepository")
struct CachingFoodCatalogRepositoryTests {
    private func food(barcode: String) -> Food {
        Food(
            name: "Nutella",
            barcode: barcode,
            kcalPer100g: 539,
            proteinPer100g: 6.3,
            carbsPer100g: 57.5,
            fatPer100g: 30.9,
            source: .openFoodFacts(code: barcode)
        )
    }

    @Test("Cache-Hit ruft die Remote-Quelle gar nicht erst auf")
    func cacheHitSkipsRemote() async throws {
        let local = FakeFoodCatalogRepository()
        local.stored = [food(barcode: "111")]
        let remote = FakeFoodDataSource()
        let sut = CachingFoodCatalogRepository(localCache: local, remoteDataSource: remote)

        let result = try await sut.food(barcode: "111")

        #expect(result?.barcode == "111")
        #expect(remote.fetchCallCount == 0)
    }

    @Test("Cache-Miss fragt Remote und persistiert den Treffer lokal")
    func cacheMissFallsBackToRemoteAndPersists() async throws {
        let local = FakeFoodCatalogRepository()
        let remote = FakeFoodDataSource()
        remote.product = food(barcode: "222")
        let sut = CachingFoodCatalogRepository(localCache: local, remoteDataSource: remote)

        let result = try await sut.food(barcode: "222")

        #expect(result?.barcode == "222")
        #expect(remote.fetchCallCount == 1)
        #expect(local.savedFoods.count == 1)
    }

    @Test("Weder Cache noch Remote haben einen Treffer: nil statt Fehler")
    func neitherCacheNorRemoteHasHit() async throws {
        let local = FakeFoodCatalogRepository()
        let remote = FakeFoodDataSource()
        let sut = CachingFoodCatalogRepository(localCache: local, remoteDataSource: remote)

        let result = try await sut.food(barcode: "333")

        #expect(result == nil)
        #expect(local.savedFoods.isEmpty)
    }
}
