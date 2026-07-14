import Foundation

/// Cache-first-Lebensmittelsuche: lokale Treffer sofort, OFF-Suche parallel, Duplikate per Barcode
/// dedupliziert (lokaler Treffer gewinnt), Ergebnis gerankt. Ein Remote-Fehlschlag (offline) lässt
/// lokale Treffer trotzdem durch. Geteilt von Log-Sheet und Gerichte-Editor.
public struct SearchFoodsUseCase: Sendable {
    private let foodCatalogRepository: any FoodCatalogRepository
    private let foodDataSource: any FoodDataSource
    private let rank = RankSearchResultsUseCase()

    public init(foodCatalogRepository: any FoodCatalogRepository, foodDataSource: any FoodDataSource) {
        self.foodCatalogRepository = foodCatalogRepository
        self.foodDataSource = foodDataSource
    }

    public func callAsFunction(query: String) async -> [Food] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        async let local = (try? foodCatalogRepository.search(localQuery: trimmed)) ?? []
        async let remote = (try? foodDataSource.search(query: trimmed)) ?? []
        let merged = await Self.merge(local: local, remote: remote)
        return rank(merged.map { SearchCandidate(food: $0) })
    }

    /// Lokale Treffer gewinnen bei Duplikaten (tragen bereits useCount/lastUsedAt).
    static func merge(local: [Food], remote: [Food]) -> [Food] {
        let localBarcodes = Set(local.compactMap(\.barcode))
        let newRemote = remote.filter { food in
            guard let barcode = food.barcode else { return true }
            return !localBarcodes.contains(barcode)
        }
        return local + newRemote
    }
}
