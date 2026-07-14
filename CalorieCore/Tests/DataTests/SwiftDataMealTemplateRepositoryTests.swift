import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataMealTemplateRepository")
struct SwiftDataMealTemplateRepositoryTests {
    private func makeSUT() throws -> SwiftDataMealTemplateRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataMealTemplateRepository(modelContainer: container)
    }

    private func template(name: String = "Frühstück") -> MealTemplate {
        MealTemplate(
            name: name,
            mealType: .breakfast,
            items: [
                MealTemplateItem(foodName: "Haferflocken", amountGrams: 50, kcal: 185, protein: 6.5, carbs: 30, fat: 3.5),
                MealTemplateItem(foodName: "Banane", amountGrams: 120, kcal: 107, protein: 1.3, carbs: 27, fat: 0.4)
            ]
        )
    }

    @Test("Speichern und Laden inkl. Items und mealType (Roundtrip)")
    func saveAndLoadRoundtrips() async throws {
        let sut = try makeSUT()
        let saved = template()
        try await sut.save(saved)

        let all = try await sut.all()
        #expect(all.count == 1)
        let loaded = try #require(all.first)
        #expect(loaded.name == "Frühstück")
        #expect(loaded.mealType == .breakfast)
        #expect(loaded.items.count == 2)
        #expect(loaded.totalKcal == 292)
        #expect(loaded.items.first?.foodName == "Haferflocken")
    }

    @Test("template(id:) liefert genau die angefragte Vorlage")
    func lookupByID() async throws {
        let sut = try makeSUT()
        let one = template(name: "A")
        let two = template(name: "B")
        try await sut.save(one)
        try await sut.save(two)

        let loaded = try await sut.template(id: two.id)
        #expect(loaded?.name == "B")
    }

    @Test("Erneutes Speichern derselben ID aktualisiert statt zu duplizieren")
    func saveUpdatesExisting() async throws {
        let sut = try makeSUT()
        var saved = template()
        try await sut.save(saved)

        saved.name = "Umbenannt"
        saved.items = [MealTemplateItem(foodName: "Nur Banane", amountGrams: 120, kcal: 107, protein: 1.3, carbs: 27, fat: 0.4)]
        try await sut.save(saved)

        let all = try await sut.all()
        #expect(all.count == 1)
        #expect(all.first?.name == "Umbenannt")
        #expect(all.first?.items.count == 1)
    }

    @Test("Löschen entfernt genau die angegebene Vorlage")
    func delete() async throws {
        let sut = try makeSUT()
        let one = template(name: "A")
        let two = template(name: "B")
        try await sut.save(one)
        try await sut.save(two)

        try await sut.delete(id: one.id)

        let all = try await sut.all()
        #expect(all.count == 1)
        #expect(all.first?.id == two.id)
    }

    @Test("Leerer Store liefert leere Liste, kein Crash")
    func emptyStore() async throws {
        let sut = try makeSUT()
        #expect(try await sut.all().isEmpty)
        #expect(try await sut.template(id: UUID()) == nil)
    }
}
