import Foundation
import Testing
@testable import Domain

@Suite("QuickList UseCases")
struct QuickListUseCaseTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private var morning: Date {
        var comps = DateComponents(); comps.year = 2026; comps.month = 7; comps.day = 13; comps.hour = 8
        return utcCalendar.date(from: comps)!
    }

    private var foodLeaf: QuickListLeaf {
        .food(id: UUID(), item: MealTemplateItem(
            foodName: "Proteinriegel", amountGrams: 60, kcal: 220, protein: 20, carbs: 18, fat: 7
        ))
    }

    @Test("Lebensmittel-Blatt ergibt genau einen Eintrag aus dem Snapshot")
    func foodLeafExpandsToOneEntry() async throws {
        let sut = LogQuickEntryUseCase(mealTemplateRepository: InMemoryMealTemplateRepository())
        let entries = try await sut(leaf: foodLeaf, consumedAt: morning, calendar: utcCalendar)
        #expect(entries.count == 1)
        #expect(entries.first?.foodName == "Proteinriegel")
        #expect(entries.first?.kcal == 220)
        #expect(entries.first?.dayKey == "2026-07-13")
    }

    @Test("Gericht-Blatt wird über das referenzierte Template expandiert")
    func mealLeafExpandsTemplate() async throws {
        let template = MealTemplate(name: "Lunch", items: [
            MealTemplateItem(foodName: "Reis", amountGrams: 100, kcal: 130, protein: 2.7, carbs: 28, fat: 0.3),
            MealTemplateItem(foodName: "Hähnchen", amountGrams: 150, kcal: 248, protein: 46, carbs: 0, fat: 5.4)
        ])
        let repo = InMemoryMealTemplateRepository(templates: [template])
        let sut = LogQuickEntryUseCase(mealTemplateRepository: repo)

        let entries = try await sut(leaf: .meal(id: UUID(), templateID: template.id), consumedAt: morning, calendar: utcCalendar)
        #expect(entries.count == 2)
        #expect(entries.map(\.foodName) == ["Reis", "Hähnchen"])
    }

    @Test("Unbekanntes Gericht ergibt keine Einträge statt Crash")
    func unknownMealYieldsNoEntries() async throws {
        let sut = LogQuickEntryUseCase(mealTemplateRepository: InMemoryMealTemplateRepository())
        let entries = try await sut(leaf: .meal(id: UUID(), templateID: UUID()), consumedAt: morning, calendar: utcCalendar)
        #expect(entries.isEmpty)
    }

    @Test("flattenedLeaves löst Ordner in Anzeigereihenfolge auf")
    func flattenedLeavesResolvesFolders() {
        let top = foodLeaf
        let inFolder1 = foodLeaf
        let inFolder2 = foodLeaf
        let list = QuickList(entries: [
            .leaf(top),
            .folder(id: UUID(), name: "Snacks", items: [inFolder1, inFolder2])
        ])
        #expect(list.flattenedLeaves.map(\.id) == [top.id, inFolder1.id, inFolder2.id])
    }
}
