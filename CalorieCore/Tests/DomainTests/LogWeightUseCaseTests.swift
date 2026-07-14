import Foundation
import Testing
@testable import Domain

@Suite("LogWeightUseCase")
struct LogWeightUseCaseTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    @Test("Ohne expliziten Kreatin-Wert wird der der letzten Messung übernommen")
    func inheritsCreatineFromLatest() async throws {
        let existing = WeightEntry(
            dayKey: "2026-07-12",
            weightKg: 82,
            recordedAt: Date(timeIntervalSince1970: 1000),
            withCreatine: true
        )
        let repo = InMemoryWeightRepository(entries: [existing])
        let sut = LogWeightUseCase(weightRepository: repo)

        let saved = try await sut(weightKg: 81.5, recordedAt: Date(timeIntervalSince1970: 2000), calendar: utcCalendar)
        #expect(saved.withCreatine == true)
        #expect(saved.weightKg == 81.5)
    }

    @Test("Ohne bisherige Messung ist der Kreatin-Default false")
    func defaultsCreatineFalseWhenEmpty() async throws {
        let repo = InMemoryWeightRepository()
        let sut = LogWeightUseCase(weightRepository: repo)

        let saved = try await sut(weightKg: 80, calendar: utcCalendar)
        #expect(saved.withCreatine == false)
        #expect(repo.storage.count == 1)
    }

    @Test("Expliziter Kreatin-Wert hat Vorrang vor dem Verlauf")
    func explicitCreatineWins() async throws {
        let existing = WeightEntry(
            dayKey: "2026-07-12",
            weightKg: 82,
            recordedAt: Date(timeIntervalSince1970: 1000),
            withCreatine: true
        )
        let repo = InMemoryWeightRepository(entries: [existing])
        let sut = LogWeightUseCase(weightRepository: repo)

        let saved = try await sut(weightKg: 81, withCreatine: false, calendar: utcCalendar)
        #expect(saved.withCreatine == false)
    }
}
