import Foundation
import Testing
@testable import Domain
@testable import FeatureDashboard

@Suite("EntryDetailViewModel")
@MainActor
struct EntryDetailViewModelTests {
    private func makeEntry() -> DiaryEntry {
        DiaryEntry(
            consumedAt: Date(),
            dayKey: "2026-07-13",
            foodName: "Apfel",
            amountGrams: 100,
            kcal: 52,
            protein: 0.3,
            carbs: 14,
            fat: 0.2
        )
    }

    @Test("Menge aktualisieren skaliert kcal/Makros proportional zur ursprünglichen Menge")
    func updateAmountScalesProportionally() async {
        let entry = makeEntry()
        let repository = FakeDiaryRepository(entries: [entry])
        let widgetRefreshing = FakeWidgetRefreshing()
        let sut = EntryDetailViewModel(entry: entry, diaryRepository: repository, widgetRefreshing: widgetRefreshing)

        let success = await sut.updateAmount(200)

        #expect(success)
        #expect(sut.entry.amountGrams == 200)
        #expect(sut.entry.kcal == 104)
        #expect(sut.entry.carbs == 28)
        #expect(widgetRefreshing.reloadCount == 1)
        #expect(repository.storage.first(where: { $0.id == entry.id })?.kcal == 104)
    }

    @Test("Ungültige Menge (0 oder negativ) wird abgelehnt, kein Crash")
    func rejectsInvalidAmount() async {
        let entry = makeEntry()
        let repository = FakeDiaryRepository(entries: [entry])
        let sut = EntryDetailViewModel(entry: entry, diaryRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        let success = await sut.updateAmount(0)

        #expect(!success)
        #expect(sut.entry.amountGrams == 100)
    }

    @Test("Löschen entfernt den Eintrag aus dem Repository")
    func deleteRemovesEntry() async {
        let entry = makeEntry()
        let repository = FakeDiaryRepository(entries: [entry])
        let widgetRefreshing = FakeWidgetRefreshing()
        let sut = EntryDetailViewModel(entry: entry, diaryRepository: repository, widgetRefreshing: widgetRefreshing)

        let success = await sut.delete()

        #expect(success)
        #expect(repository.storage.isEmpty)
        #expect(widgetRefreshing.reloadCount == 1)
    }

    @Test("Repository-Fehler beim Speichern liefert false statt Crash")
    func saveFailureReturnsFalse() async {
        let entry = makeEntry()
        let repository = FakeDiaryRepository(entries: [entry])
        repository.shouldThrow = true
        let sut = EntryDetailViewModel(entry: entry, diaryRepository: repository, widgetRefreshing: FakeWidgetRefreshing())

        let success = await sut.updateAmount(150)

        #expect(!success)
    }
}
