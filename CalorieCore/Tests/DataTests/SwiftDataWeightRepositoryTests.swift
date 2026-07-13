import Foundation
import Testing
@testable import Data
@testable import Domain

@Suite("SwiftDataWeightRepository")
struct SwiftDataWeightRepositoryTests {
    private func makeSUT() throws -> SwiftDataWeightRepository {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        return SwiftDataWeightRepository(modelContainer: container)
    }

    private func entry(_ weightKg: Double, dayKey: String, daysAgo: Int = 0) -> WeightEntry {
        WeightEntry(dayKey: dayKey, weightKg: weightKg, recordedAt: Date().addingTimeInterval(-Double(daysAgo) * 86400))
    }

    @Test("Speichern und Bereichsabfrage liefert die Messung zurück")
    func saveAndQueryRange() async throws {
        let sut = try makeSUT()
        let saved = entry(80, dayKey: "2026-07-13")
        try await sut.save(saved)

        let loaded = try await sut.entries(fromDayKey: "2026-07-01", toDayKey: "2026-07-31")
        #expect(loaded.count == 1)
        #expect(loaded.first?.weightKg == 80)
    }

    @Test("Bereichsabfrage lässt Messungen außerhalb des Bereichs weg")
    func rangeQueryExcludesOutsideEntries() async throws {
        let sut = try makeSUT()
        try await sut.save(entry(80, dayKey: "2026-06-01"))
        try await sut.save(entry(79, dayKey: "2026-07-13"))

        let loaded = try await sut.entries(fromDayKey: "2026-07-01", toDayKey: "2026-07-31")
        #expect(loaded.count == 1)
        #expect(loaded.first?.weightKg == 79)
    }

    @Test("latest() liefert die zeitlich jüngste Messung")
    func latestReturnsMostRecent() async throws {
        let sut = try makeSUT()
        try await sut.save(entry(82, dayKey: "2026-07-11", daysAgo: 2))
        try await sut.save(entry(80, dayKey: "2026-07-13", daysAgo: 0))
        try await sut.save(entry(81, dayKey: "2026-07-12", daysAgo: 1))

        let latest = try await sut.latest()
        #expect(latest?.weightKg == 80)
    }

    @Test("latest() ohne Messungen liefert nil, kein Crash")
    func latestWithNoEntries() async throws {
        let sut = try makeSUT()
        let latest = try await sut.latest()
        #expect(latest == nil)
    }

    @Test("Löschen entfernt genau den angegebenen Eintrag")
    func delete() async throws {
        let sut = try makeSUT()
        let toDelete = entry(80, dayKey: "2026-07-13")
        let toKeep = entry(81, dayKey: "2026-07-13")
        try await sut.save(toDelete)
        try await sut.save(toKeep)

        try await sut.delete(entryID: toDelete.id)

        let remaining = try await sut.entries(fromDayKey: "2026-01-01", toDayKey: "2026-12-31")
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == toKeep.id)
    }

    @Test("Erneutes Speichern derselben ID aktualisiert statt zu duplizieren")
    func saveUpdatesExistingEntry() async throws {
        let sut = try makeSUT()
        var entry = entry(80, dayKey: "2026-07-13")
        try await sut.save(entry)

        entry.weightKg = 79.5
        try await sut.save(entry)

        let all = try await sut.entries(fromDayKey: "2026-01-01", toDayKey: "2026-12-31")
        #expect(all.count == 1)
        #expect(all.first?.weightKg == 79.5)
    }

    @Test("withCreatine wird persistiert und beim Update mitgeführt (Roundtrip)")
    func withCreatineRoundtrips() async throws {
        let sut = try makeSUT()
        var entry = WeightEntry(dayKey: "2026-07-13", weightKg: 80, recordedAt: Date(), withCreatine: true)
        try await sut.save(entry)

        var loaded = try await sut.entries(fromDayKey: "2026-01-01", toDayKey: "2026-12-31")
        #expect(loaded.first?.withCreatine == true)

        entry.withCreatine = false
        try await sut.save(entry)
        loaded = try await sut.entries(fromDayKey: "2026-01-01", toDayKey: "2026-12-31")
        #expect(loaded.count == 1)
        #expect(loaded.first?.withCreatine == false)
    }
}
