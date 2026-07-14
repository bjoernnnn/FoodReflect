import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataQuickListRepository")
struct SwiftDataQuickListRepositoryTests {
    private func makeSUT() throws -> SwiftDataQuickListRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataQuickListRepository(modelContainer: container)
    }

    private func foodLeaf(_ name: String) -> QuickListLeaf {
        .food(id: UUID(), item: MealTemplateItem(foodName: name, amountGrams: 60, kcal: 220, protein: 20, carbs: 18, fat: 7))
    }

    @Test("Leerer Store liefert .empty, kein Crash")
    func emptyLoad() async throws {
        let sut = try makeSUT()
        let loaded = try await sut.load()
        #expect(loaded.entries.isEmpty)
    }

    @Test("Speichern und Laden erhält Reihenfolge, Blätter und Ordner (Roundtrip)")
    func saveAndLoadRoundtrips() async throws {
        let sut = try makeSUT()
        let riegel = foodLeaf("Proteinriegel")
        let mealID = UUID()
        let list = QuickList(entries: [
            .leaf(riegel),
            .leaf(.meal(id: UUID(), templateID: mealID)),
            .folder(id: UUID(), name: "Snacks", items: [foodLeaf("Apfel"), foodLeaf("Nüsse")])
        ])
        try await sut.save(list)

        let loaded = try await sut.load()
        #expect(loaded.entries.count == 3)
        #expect(loaded.flattenedLeaves.count == 4)
        if case let .leaf(.food(_, item)) = loaded.entries.first {
            #expect(item.foodName == "Proteinriegel")
        } else {
            Issue.record("erstes Element sollte ein Lebensmittel-Blatt sein")
        }
        if case let .folder(_, name, items) = loaded.entries.last {
            #expect(name == "Snacks")
            #expect(items.count == 2)
        } else {
            Issue.record("letztes Element sollte ein Ordner sein")
        }
    }

    @Test("Erneutes Speichern überschreibt statt eine zweite Zeile anzulegen")
    func saveOverwritesSingleton() async throws {
        let sut = try makeSUT()
        try await sut.save(QuickList(entries: [.leaf(foodLeaf("A"))]))
        try await sut.save(QuickList(entries: [.leaf(foodLeaf("B")), .leaf(foodLeaf("C"))]))

        let loaded = try await sut.load()
        #expect(loaded.entries.count == 2)
    }
}
