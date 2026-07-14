import Domain
import Foundation
import Testing
@testable import FeatureMeals

@Suite("QuickListEditorViewModel")
@MainActor
struct QuickListEditorViewModelTests {
    private func makeSUT(
        quickList: QuickList = .empty,
        templates: [MealTemplate] = []
    ) -> (QuickListEditorViewModel, FakeQuickListRepository) {
        let quickRepo = FakeQuickListRepository(quickList: quickList)
        let mealRepo = FakeMealTemplateRepository(templates: templates)
        let sut = QuickListEditorViewModel(
            quickListRepository: quickRepo,
            mealTemplateRepository: mealRepo,
            foodCatalogRepository: FakeFoodCatalogRepository(),
            foodDataSource: FakeFoodDataSource()
        )
        return (sut, quickRepo)
    }

    @Test("Laden ohne gespeicherte Liste liefert eine leere Schnellauswahl")
    func loadEmpty() async {
        let (sut, _) = makeSUT()
        await sut.load()
        #expect(sut.isLoaded)
        #expect(sut.quickList.entries.isEmpty)
    }

    @Test("addFood hängt ein Lebensmittel-Blatt an und persistiert sofort")
    func addFoodPersists() async {
        let (sut, repo) = makeSUT()
        await sut.load()

        await sut.addFood(TestFood.make(name: "Apfel", kcalPer100g: 52), amountGrams: 100)

        #expect(sut.quickList.entries.count == 1)
        #expect(repo.saveCount >= 1)
        let leaf = sut.quickList.flattenedLeaves.first
        #expect(leaf.map { sut.displayName(for: $0) } == "Apfel")
    }

    @Test("addMeal referenziert ein Gericht und zeigt dessen Name + kcal")
    func addMealShowsTemplateData() async {
        let meal = MealTemplate(
            name: "Frühstück",
            items: [MealTemplateItem(foodName: "Ei", amountGrams: 100, kcal: 155, protein: 13, carbs: 1, fat: 11)]
        )
        let (sut, _) = makeSUT(templates: [meal])
        await sut.load()

        await sut.addMeal(templateID: meal.id)

        let leaf = try? #require(sut.quickList.flattenedLeaves.first)
        #expect(leaf.map { sut.isMeal($0) } == true)
        #expect(leaf.map { sut.displayName(for: $0) } == "Frühstück")
        #expect(leaf.map { sut.kcal(for: $0) } == 155)
    }

    @Test("createFolder legt einen Ordner an, leerer Name wird ignoriert")
    func createFolder() async {
        let (sut, _) = makeSUT()
        await sut.load()

        await sut.createFolder(name: "   ")
        #expect(sut.quickList.entries.isEmpty)

        await sut.createFolder(name: "Snacks")
        #expect(sut.quickList.entries.count == 1)
    }

    @Test("moveLeaf schiebt ein Blatt in einen Ordner und wieder heraus")
    func moveLeafInAndOut() async {
        let (sut, _) = makeSUT()
        await sut.load()
        await sut.createFolder(name: "Snacks")
        await sut.addFood(TestFood.make(name: "Nuss"), amountGrams: 30)

        let folderID = folderID(in: sut)
        let leafID = topLevelLeafID(in: sut)

        await sut.moveLeaf(leafID, toFolder: folderID)

        // Blatt ist nicht mehr auf oberster Ebene, sondern im Ordner.
        #expect(topLevelLeafCount(in: sut) == 0)
        #expect(folderLeafCount(in: sut) == 1)

        await sut.moveLeaf(leafID, toFolder: nil)
        #expect(topLevelLeafCount(in: sut) == 1)
        #expect(folderLeafCount(in: sut) == 0)
    }

    @Test("delete entfernt sowohl Top-Level-Blätter als auch Blätter in Ordnern")
    func deleteRemovesLeaf() async {
        let (sut, _) = makeSUT()
        await sut.load()
        await sut.addFood(TestFood.make(name: "Riegel"), amountGrams: 40)
        let leafID = topLevelLeafID(in: sut)

        await sut.delete(entryID: leafID)
        #expect(sut.quickList.entries.isEmpty)
    }

    // MARK: - Helpers

    private func folderID(in sut: QuickListEditorViewModel) -> UUID {
        for entry in sut.quickList.entries {
            if case let .folder(id, _, _) = entry {
                return id
            }
        }
        return UUID()
    }

    private func topLevelLeafID(in sut: QuickListEditorViewModel) -> UUID {
        for entry in sut.quickList.entries {
            if case let .leaf(leaf) = entry {
                return leaf.id
            }
        }
        return UUID()
    }

    private func topLevelLeafCount(in sut: QuickListEditorViewModel) -> Int {
        sut.quickList.entries.filter {
            if case .leaf = $0 {
                true
            } else {
                false
            }
        }.count
    }

    private func folderLeafCount(in sut: QuickListEditorViewModel) -> Int {
        sut.quickList.entries.reduce(0) { acc, entry in
            if case let .folder(_, _, items) = entry {
                return acc + items.count
            }
            return acc
        }
    }
}
