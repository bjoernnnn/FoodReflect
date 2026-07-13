import Foundation
import Testing
@testable import DesignSystem
@testable import Domain
@testable import FeatureWeight

@Suite("WeightViewModel")
@MainActor
struct WeightViewModelTests {
    private let fixedCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test("Ohne Messungen ergibt .empty statt Crash")
    func noEntriesYieldsEmpty() async {
        let repository = FakeWeightRepository()
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar)

        await sut.load()

        guard case .empty = sut.state else {
            Issue.record("expected .empty, got \(sut.state)")
            return
        }
    }

    @Test("Speichern fügt einen Eintrag hinzu und aktualisiert den Trend")
    func saveAddsEntryAndUpdatesTrend() async {
        let repository = FakeWeightRepository()
        let widgetRefreshing = FakeWidgetRefreshing()
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: widgetRefreshing, calendar: fixedCalendar)

        await sut.save(weightKg: 80.5, date: Date())

        guard case let .loaded(entries) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 80.5)
        #expect(sut.trend?.latest?.weightKg == 80.5)
        #expect(widgetRefreshing.reloadCount == 1)
    }

    @Test("Löschen entfernt den Eintrag")
    func deleteRemovesEntry() async {
        let existing = WeightEntry(dayKey: "2026-07-13", weightKg: 80, recordedAt: Date())
        let repository = FakeWeightRepository(entries: [existing])
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar)
        await sut.load()

        await sut.delete(entryID: existing.id)

        guard case .empty = sut.state else {
            Issue.record("expected .empty after deleting the only entry, got \(sut.state)")
            return
        }
    }

    @Test("Repository-Fehler beim Laden ergibt .error statt Crash")
    func loadFailureSurfacesErrorState() async {
        let repository = FakeWeightRepository()
        repository.shouldThrow = true
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar)

        await sut.load()

        guard case .error = sut.state else {
            Issue.record("expected .error, got \(sut.state)")
            return
        }
    }

    @Test("loadAll() lädt auch Messungen älter als 90 Tage")
    func loadAllIncludesOldEntries() async {
        let oldDate = Calendar.current.date(byAdding: .day, value: -200, to: Date()) ?? Date()
        let old = WeightEntry(dayKey: DayKey.make(for: oldDate, calendar: fixedCalendar), weightKg: 90, recordedAt: oldDate)
        let repository = FakeWeightRepository(entries: [old])
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar)

        await sut.loadAll()

        guard case let .loaded(entries) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(entries.count == 1)
    }

    @Test("Speichern mit entryID bearbeitet den bestehenden Eintrag statt einen zweiten anzulegen")
    func saveWithEntryIDEditsInPlace() async {
        let existing = WeightEntry(dayKey: "2026-07-13", weightKg: 80, recordedAt: Date())
        let repository = FakeWeightRepository(entries: [existing])
        let sut = WeightViewModel(weightRepository: repository, widgetRefreshing: FakeWidgetRefreshing(), calendar: fixedCalendar)
        await sut.load()

        await sut.save(entryID: existing.id, weightKg: 79.5, date: existing.recordedAt)

        guard case let .loaded(entries) = sut.state else {
            Issue.record("expected .loaded, got \(sut.state)")
            return
        }
        #expect(entries.count == 1)
        #expect(entries.first?.weightKg == 79.5)
        #expect(entries.first?.id == existing.id)
    }
}
