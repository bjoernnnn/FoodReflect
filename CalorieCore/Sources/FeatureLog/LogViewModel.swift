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
    private let searchFoods: SearchFoodsUseCase

    public init(
        foodCatalogRepository: any FoodCatalogRepository,
        foodDataSource: any FoodDataSource,
        diaryRepository: any DiaryRepository,
        widgetRefreshing: any WidgetRefreshing
    ) {
        self.foodCatalogRepository = foodCatalogRepository
        self.diaryRepository = diaryRepository
        self.widgetRefreshing = widgetRefreshing
        searchFoods = SearchFoodsUseCase(foodCatalogRepository: foodCatalogRepository, foodDataSource: foodDataSource)
    }

    /// Cache-first: lokale Treffer sind sofort da, OFF-Suche läuft parallel dazu.
    /// Ein Fehlschlag der Remote-Suche (z. B. offline) lässt lokale Treffer trotzdem durch.
    public func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .empty
            return
        }
        state = .loading
        let results = await searchFoods(query: query)
        state = results.isEmpty ? .empty : .loaded(results)
    }
}
