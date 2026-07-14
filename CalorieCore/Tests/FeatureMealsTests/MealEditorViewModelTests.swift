import Domain
import Foundation
import Testing
@testable import FeatureMeals

@Suite("MealEditorViewModel")
@MainActor
struct MealEditorViewModelTests {
    private func makeSUT(
        existing: MealTemplate? = nil,
        catalog: FakeFoodCatalogRepository = FakeFoodCatalogRepository()
    ) -> (MealEditorViewModel, FakeMealTemplateRepository) {
        let repo = FakeMealTemplateRepository()
        let sut = MealEditorViewModel(
            existing: existing,
            repository: repo,
            foodCatalogRepository: catalog,
            foodDataSource: FakeFoodDataSource()
        )
        return (sut, repo)
    }

    @Test("Neues Gericht startet leer und kann nicht gespeichert werden")
    func emptyCannotSave() {
        let (sut, _) = makeSUT()
        #expect(sut.name.isEmpty)
        #expect(sut.items.isEmpty)
        #expect(sut.canSave == false)
    }

    @Test("addFood erzeugt ein Item mit skaliertem Snapshot und aktualisiert die Summen")
    func addFoodScalesAndTotals() {
        let (sut, _) = makeSUT()
        let food = TestFood.make(name: "Haferflocken", kcalPer100g: 370)

        sut.addFood(food, amountGrams: 50)

        #expect(sut.items.count == 1)
        #expect(sut.items[0].foodName == "Haferflocken")
        #expect(sut.items[0].amountGrams == 50)
        #expect(sut.totalKcal == 185) // 370 * 0.5
    }

    @Test("Name + mindestens ein Item erlauben Speichern und persistieren das Gericht")
    func savesWhenValid() async {
        let (sut, repo) = makeSUT()
        sut.name = "Porridge"
        sut.mealType = .breakfast
        sut.addFood(TestFood.make(name: "Haferflocken", kcalPer100g: 370), amountGrams: 50)

        #expect(sut.canSave)
        let didSave = await sut.save()

        #expect(didSave)
        #expect(repo.storage.count == 1)
        #expect(repo.storage[0].name == "Porridge")
        #expect(repo.storage[0].mealType == .breakfast)
        #expect(repo.storage[0].items.count == 1)
    }

    @Test("Bestehendes Gericht behält seine ID beim Bearbeiten (Upsert statt Duplikat)")
    func editKeepsID() async {
        let existing = MealTemplate(
            id: UUID(),
            name: "Alt",
            mealType: .lunch,
            items: [MealTemplateItem(foodName: "Reis", amountGrams: 100, kcal: 130, protein: 3, carbs: 28, fat: 0)]
        )
        let repo = FakeMealTemplateRepository(templates: [existing])
        let sut = MealEditorViewModel(
            existing: existing,
            repository: repo,
            foodCatalogRepository: FakeFoodCatalogRepository(),
            foodDataSource: FakeFoodDataSource()
        )
        sut.name = "Neu"

        _ = await sut.save()

        #expect(repo.storage.count == 1)
        #expect(repo.storage[0].id == existing.id)
        #expect(repo.storage[0].name == "Neu")
    }

    @Test("Suche liefert lokale Treffer als geladenen Zustand")
    func searchLoadsResults() async {
        let catalog = FakeFoodCatalogRepository()
        catalog.localResults = [TestFood.make(name: "Banane")]
        let (sut, _) = makeSUT(catalog: catalog)

        await sut.search(query: "Ban")

        if case let .loaded(results) = sut.searchState {
            #expect(results.contains { $0.name == "Banane" })
        } else {
            Issue.record("Erwartet .loaded, war \(sut.searchState)")
        }
    }
}
