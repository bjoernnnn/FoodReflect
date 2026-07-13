import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class LogViewModel {
    public private(set) var state: ViewState<[Food]> = .empty

    let foodCatalogRepository: any FoodCatalogRepository
    let diaryRepository: any DiaryRepository
    let widgetRefreshing: any WidgetRefreshing
    private let foodDataSource: any FoodDataSource
    private let rankSearchResults = RankSearchResultsUseCase()

    public init(
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource,
        diaryRepository: any DiaryRepository,
        widgetRefreshing: any WidgetRefreshing
    ) {
        self.foodCatalogRepository = foodCatalogRepository
        self.foodDataSource = foodDataSource
        self.diaryRepository = diaryRepository
        self.widgetRefreshing = widgetRefreshing
    }

    /// Cache-first: lokale Treffer sind sofort da, OFF-Suche läuft parallel dazu.
    /// Ein Fehlschlag der Remote-Suche (z. B. offline) lässt lokale Treffer trotzdem durch.
    public func search(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .empty
            return
        }
        state = .loading

        async let local = await (try? foodCatalogRepository.search(localQuery: trimmed)) ?? []
        async let remote = await (try? foodDataSource.search(query: trimmed)) ?? []
        let merged = await Self.merge(local: local, remote: remote)

        guard !merged.isEmpty else {
            state = .empty
            return
        }
        state = .loaded(rankSearchResults(merged.map { SearchCandidate(food: $0) }))
    }

    /// Lokale Treffer gewinnen bei Duplikaten (tragen bereits useCount/lastUsedAt).
    private static func merge(local: [Food], remote: [Food]) -> [Food] {
        let localBarcodes = Set(local.compactMap(\.barcode))
        let newRemote = remote.filter { food in
            guard let barcode = food.barcode else { return true }
            return !localBarcodes.contains(barcode)
        }
        return local + newRemote
    }
}
