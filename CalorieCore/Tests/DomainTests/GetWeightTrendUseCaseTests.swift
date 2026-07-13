import Foundation
import Testing
@testable import Domain

@Suite("GetWeightTrendUseCase")
struct GetWeightTrendUseCaseTests {
    private func entry(_ weightKg: Double, daysAgo: Int) -> WeightEntry {
        let date = Date().addingTimeInterval(-Double(daysAgo) * 86400)
        return WeightEntry(dayKey: DayKey.make(for: date), weightKg: weightKg, recordedAt: date)
    }

    @Test("Keine Messungen ergibt komplett leeren Trend, kein Crash")
    func noEntries() {
        let trend = GetWeightTrendUseCase.aggregate(entries: [])
        #expect(trend.latest == nil)
        #expect(trend.averageWeightKg == nil)
        #expect(trend.deltaFromPreviousMeasurement == nil)
    }

    @Test("Eine einzige Messung: kein Delta, da keine Vorherige existiert")
    func singleEntry() {
        let only = entry(80, daysAgo: 0)
        let trend = GetWeightTrendUseCase.aggregate(entries: [only])
        #expect(trend.latest == only)
        #expect(trend.averageWeightKg == 80)
        #expect(trend.deltaFromPreviousMeasurement == nil)
    }

    @Test("Mehrere Messungen: Durchschnitt korrekt, Delta zur letzten vorherigen Messung, unabhängig von Sortierreihenfolge")
    func multipleEntriesOutOfOrder() {
        let oldest = entry(82, daysAgo: 2)
        let middle = entry(81, daysAgo: 1)
        let newest = entry(79, daysAgo: 0)
        let trend = GetWeightTrendUseCase.aggregate(entries: [newest, oldest, middle])

        #expect(trend.latest == newest)
        #expect(abs((trend.averageWeightKg ?? 0) - (82.0 + 81.0 + 79.0) / 3.0) < 0.0001)
        #expect(trend.deltaFromPreviousMeasurement == -2) // 79 - 81
    }

    @Test("Zunahme ergibt positives Delta")
    func weightGainYieldsPositiveDelta() {
        let trend = GetWeightTrendUseCase.aggregate(entries: [entry(80, daysAgo: 1), entry(81, daysAgo: 0)])
        #expect(trend.deltaFromPreviousMeasurement == 1)
    }
}
