import Foundation

/// Lokaler Katalog-Cache. Kombiniert Cache-Hits mit Remote-Lookups über `FoodDataSource`.
public protocol FoodCatalogRepository: Sendable {
    func food(barcode: String) async throws(DomainError) -> Food?
    func search(localQuery query: String) async throws(DomainError) -> [Food]
    func save(_ food: Food) async throws(DomainError)
    func recordUsage(foodID: UUID, at date: Date) async throws(DomainError)
}
