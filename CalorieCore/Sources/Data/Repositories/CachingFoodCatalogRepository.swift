import Domain
import Foundation

/// Verdrahtet den lokalen Cache mit der Remote-Quelle gemäß Abschnitt 4:
/// Cache-Hit zuerst, sonst Remote-Lookup + Persistieren. `search(localQuery:)`
/// bleibt bewusst rein lokal – das Mergen mit Remote-Suchtreffern ist Aufgabe
/// des Log-Sheets (Phase 5), da dort Debouncing und Ranking zusammenlaufen.
public actor CachingFoodCatalogRepository: FoodCatalogRepository {
    private let localCache: any FoodCatalogRepository
    private let remoteDataSource: any FoodDataSource

    public init(localCache: any FoodCatalogRepository, remoteDataSource: any FoodDataSource) {
        self.localCache = localCache
        self.remoteDataSource = remoteDataSource
    }

    public func food(barcode: String) async throws(DomainError) -> Food? {
        if let cached = try await localCache.food(barcode: barcode) {
            return cached
        }
        guard let remote = try await remoteDataSource.fetchProduct(barcode: barcode) else {
            return nil
        }
        try await localCache.save(remote)
        return remote
    }

    public func search(localQuery query: String) async throws(DomainError) -> [Food] {
        try await localCache.search(localQuery: query)
    }

    public func save(_ food: Food) async throws(DomainError) {
        try await localCache.save(food)
    }

    public func recordUsage(foodID: UUID, at date: Date) async throws(DomainError) {
        try await localCache.recordUsage(foodID: foodID, at: date)
    }
}
