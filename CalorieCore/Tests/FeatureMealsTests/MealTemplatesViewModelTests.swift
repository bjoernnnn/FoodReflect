import Domain
import Foundation
import Testing
@testable import FeatureMeals

@Suite("MealTemplatesViewModel")
@MainActor
struct MealTemplatesViewModelTests {
    private func template(_ name: String) -> MealTemplate {
        MealTemplate(
            name: name,
            items: [MealTemplateItem(foodName: "X", amountGrams: 100, kcal: 100, protein: 1, carbs: 1, fat: 1)]
        )
    }

    @Test("Leeres Repository führt zu .empty")
    func emptyState() async {
        let sut = MealTemplatesViewModel(repository: FakeMealTemplateRepository())
        await sut.load()
        if case .empty = sut.state {} else {
            Issue.record("Erwartet .empty, war \(sut.state)")
        }
    }

    @Test("Gerichte werden geladen")
    func loadsTemplates() async {
        let repo = FakeMealTemplateRepository(templates: [template("A"), template("B")])
        let sut = MealTemplatesViewModel(repository: repo)
        await sut.load()
        if case let .loaded(items) = sut.state {
            #expect(items.count == 2)
        } else {
            Issue.record("Erwartet .loaded, war \(sut.state)")
        }
    }

    @Test("Fehler beim Laden führt zu .error")
    func loadError() async {
        let repo = FakeMealTemplateRepository()
        repo.shouldThrow = true
        let sut = MealTemplatesViewModel(repository: repo)
        await sut.load()
        if case .error = sut.state {} else {
            Issue.record("Erwartet .error, war \(sut.state)")
        }
    }

    @Test("Löschen entfernt das Gericht und lädt neu")
    func deletesTemplate() async {
        let keep = template("Behalten")
        let drop = template("Löschen")
        let repo = FakeMealTemplateRepository(templates: [keep, drop])
        let sut = MealTemplatesViewModel(repository: repo)
        await sut.load()

        await sut.delete(id: drop.id)

        if case let .loaded(items) = sut.state {
            #expect(items.count == 1)
            #expect(items[0].id == keep.id)
        } else {
            Issue.record("Erwartet .loaded, war \(sut.state)")
        }
    }
}
