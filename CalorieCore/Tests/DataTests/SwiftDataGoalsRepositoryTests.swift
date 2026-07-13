import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataGoalsRepository")
struct SwiftDataGoalsRepositoryTests {
    private func makeSUT() throws -> SwiftDataGoalsRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataGoalsRepository(modelContainer: container)
    }

    @Test("Ohne gespeicherte Ziele liefert currentGoals() nil")
    func noGoalsYet() async throws {
        let sut = try makeSUT()
        let goals = try await sut.currentGoals()
        #expect(goals == nil)
    }

    @Test("Speichern und Laden der Ziele")
    func saveAndLoad() async throws {
        let sut = try makeSUT()
        let goals = MacroGoals(dailyKcal: 2200, proteinGrams: 165, carbsGrams: 220, fatGrams: 73, isCustomized: true)
        try await sut.save(goals)

        let loaded = try await sut.currentGoals()
        #expect(loaded == goals)
    }

    @Test("Erneutes Speichern überschreibt die einzige Zeile statt eine zweite anzulegen")
    func saveOverwritesSingleRow() async throws {
        let sut = try makeSUT()
        let first = MacroGoals(dailyKcal: 2000, proteinGrams: 150, carbsGrams: 200, fatGrams: 67, isCustomized: false)
        let second = MacroGoals(dailyKcal: 1800, proteinGrams: 135, carbsGrams: 180, fatGrams: 60, isCustomized: true)
        try await sut.save(first)
        try await sut.save(second)

        let loaded = try await sut.currentGoals()
        #expect(loaded?.dailyKcal == 1800)
        #expect(loaded?.isCustomized == true)
    }
}
