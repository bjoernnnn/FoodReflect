import Testing
@testable import DesignSystem
@testable import Domain
@testable import FeatureLog

@Suite("LogViewModel")
@MainActor
struct LogViewModelTests {
    private func food(_ name: String, barcode: String? = nil, kcal: Double = 100, useCount: Int = 0) -> Food {
        Food(
            name: name,
            barcode: barcode,
            kcalPer100g: kcal,
            proteinPer100g: 5,
            carbsPer100g: 5,
            fatPer100g: 5,
            source: .manual,
            useCount: useCount
        )
    }

    @Test("Leere Suchanfrage ergibt .empty ohne Netzwerkaufruf")
    func emptyQueryYieldsEmpty() async {
        let catalog = FakeFoodCatalogRepository()
        let dataSource = FakeFoodDataSource()
        let sut = LogViewModel(foodCatalogRepository: catalog, foodDataSource: dataSource, diaryRepository: FakeDiaryRepository())

        await sut.search(query: "   ")

        guard case .empty = sut.state else {
            Issue.record("expected .empty, got \(sut.state)")
            return
        }
    }

    @Test("Kombiniert lokale und Remote-Treffer")
    func mergesLocalAndRemoteResults() async {
        let catalog = FakeFoodCatalogRepository()
        catalog.localResults = [food("Apfel Bio", barcode: "111")]
        let dataSource = FakeFoodDataSource()
        dataSource.remoteResults = [food("Apfelsaft", barcode: "222")]
        let sut = LogViewModel(foodCatalogRepository: catalog, foodDataSource: dataSource, diaryRepository: FakeDiaryRepository())

        await sut.search(query: "Apfel")

        guard case let .loaded(foods) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(foods.count == 2)
        #expect(Set(foods.map(\.name)) == ["Apfel Bio", "Apfelsaft"])
    }

    @Test("Duplikate (gleicher Barcode) werden dedupliziert, lokaler Treffer gewinnt")
    func deduplicatesByBarcode() async {
        let catalog = FakeFoodCatalogRepository()
        catalog.localResults = [food("Nutella (lokal, oft genutzt)", barcode: "999", useCount: 5)]
        let dataSource = FakeFoodDataSource()
        dataSource.remoteResults = [food("Nutella (remote)", barcode: "999")]
        let sut = LogViewModel(foodCatalogRepository: catalog, foodDataSource: dataSource, diaryRepository: FakeDiaryRepository())

        await sut.search(query: "Nutella")

        guard case let .loaded(foods) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(foods.count == 1)
        #expect(foods.first?.name == "Nutella (lokal, oft genutzt)")
    }

    @Test("Remote-Fehler (offline) lässt lokale Treffer trotzdem durch, kein Crash")
    func remoteFailureStillShowsLocalResults() async {
        let catalog = FakeFoodCatalogRepository()
        catalog.localResults = [food("Apfel")]
        let dataSource = FakeFoodDataSource()
        dataSource.shouldThrow = true
        let sut = LogViewModel(foodCatalogRepository: catalog, foodDataSource: dataSource, diaryRepository: FakeDiaryRepository())

        await sut.search(query: "Apfel")

        guard case let .loaded(foods) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(foods.count == 1)
    }

    @Test("Keine Treffer irgendwo ergibt .empty")
    func noResultsAnywhereYieldsEmpty() async {
        let sut = LogViewModel(
            foodCatalogRepository: FakeFoodCatalogRepository(),
            foodDataSource: FakeFoodDataSource(),
            diaryRepository: FakeDiaryRepository()
        )

        await sut.search(query: "Nichts")

        guard case .empty = sut.state else {
            Issue.record("expected .empty, got \(sut.state)")
            return
        }
    }
}
