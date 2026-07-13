import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataDiaryRepository")
struct SwiftDataDiaryRepositoryTests {
    private func makeSUT() throws -> SwiftDataDiaryRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataDiaryRepository(modelContainer: container)
    }

    private func entry(dayKey: String, kcal: Double = 300) -> DiaryEntry {
        DiaryEntry(
            consumedAt: Date(),
            dayKey: dayKey,
            foodName: "Apfel",
            amountGrams: 100,
            kcal: kcal,
            protein: 0,
            carbs: 0,
            fat: 0
        )
    }

    @Test("Speichern und Laden eines Eintrags über den Tages-Key")
    func saveAndLoadByDay() async throws {
        let sut = try makeSUT()
        let saved = entry(dayKey: "2026-07-13")
        try await sut.save(saved)

        let loaded = try await sut.entries(on: "2026-07-13")
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == saved.id)
        #expect(loaded.first?.kcal == 300)
    }

    @Test("Andere Tage werden bei Tagesabfrage nicht mitgeliefert")
    func dayQueryIsIsolated() async throws {
        let sut = try makeSUT()
        try await sut.save(entry(dayKey: "2026-07-13"))
        try await sut.save(entry(dayKey: "2026-07-12"))

        let loaded = try await sut.entries(on: "2026-07-13")
        #expect(loaded.count == 1)
    }

    @Test("Wochenabfrage liefert alle Einträge im Bereich (lexikografisch)")
    func rangeQuery() async throws {
        let sut = try makeSUT()
        try await sut.save(entry(dayKey: "2026-07-06"))
        try await sut.save(entry(dayKey: "2026-07-10"))
        try await sut.save(entry(dayKey: "2026-07-13"))
        try await sut.save(entry(dayKey: "2026-07-14")) // außerhalb des Bereichs

        let loaded = try await sut.entries(fromDayKey: "2026-07-07", toDayKey: "2026-07-13")
        #expect(loaded.count == 2)
        #expect(loaded.map(\.dayKey) == ["2026-07-10", "2026-07-13"])
    }

    @Test("Löschen entfernt genau den angegebenen Eintrag")
    func delete() async throws {
        let sut = try makeSUT()
        let entryToDelete = entry(dayKey: "2026-07-13")
        let entryToKeep = entry(dayKey: "2026-07-13")
        try await sut.save(entryToDelete)
        try await sut.save(entryToKeep)

        try await sut.delete(entryID: entryToDelete.id)

        let remaining = try await sut.entries(on: "2026-07-13")
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == entryToKeep.id)
    }

    @Test("Löschen einer unbekannten ID ist ein No-Op, kein Fehler")
    func deleteUnknownIDIsNoop() async throws {
        let sut = try makeSUT()
        try await sut.delete(entryID: UUID())
    }

    @Test("Leerer Store liefert leere Liste, kein Crash")
    func emptyStore() async throws {
        let sut = try makeSUT()
        let loaded = try await sut.entries(on: "2026-07-13")
        #expect(loaded.isEmpty)
    }

    @Test("mealType wird persistiert und beim Update mitgeführt (Roundtrip)")
    func mealTypeRoundtrips() async throws {
        let sut = try makeSUT()
        var entry = DiaryEntry(
            consumedAt: Date(), dayKey: "2026-07-13", foodName: "Haferflocken",
            amountGrams: 50, kcal: 180, protein: 6, carbs: 30, fat: 3, mealType: .breakfast
        )
        try await sut.save(entry)
        var loaded = try await sut.entries(on: "2026-07-13")
        #expect(loaded.first?.mealType == .breakfast)

        entry.mealType = .lunch
        try await sut.save(entry)
        loaded = try await sut.entries(on: "2026-07-13")
        #expect(loaded.count == 1)
        #expect(loaded.first?.mealType == .lunch)
    }
}
