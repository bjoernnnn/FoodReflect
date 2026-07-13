import Domain
import Foundation

@Observable
@MainActor
final class EntryDetailViewModel {
    private(set) var entry: DiaryEntry
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let diaryRepository: any DiaryRepository
    private let widgetRefreshing: any WidgetRefreshing

    init(entry: DiaryEntry, diaryRepository: any DiaryRepository, widgetRefreshing: any WidgetRefreshing) {
        self.entry = entry
        self.diaryRepository = diaryRepository
        self.widgetRefreshing = widgetRefreshing
    }

    /// Skaliert kcal/Makros proportional zur neuen Menge, ausgehend vom Nährwert-Snapshot dieses
    /// Eintrags – kein Food-Lookup, damit spätere Food-Änderungen die Historie nicht verfälschen.
    func updateAmount(_ newAmountGrams: Double) async -> Bool {
        guard newAmountGrams > 0, entry.amountGrams > 0 else { return false }
        let ratio = newAmountGrams / entry.amountGrams
        var updated = entry
        updated.amountGrams = newAmountGrams
        updated.kcal = entry.kcal * ratio
        updated.protein = entry.protein * ratio
        updated.carbs = entry.carbs * ratio
        updated.fat = entry.fat * ratio

        isSaving = true
        defer { isSaving = false }
        do {
            try await diaryRepository.save(updated)
            widgetRefreshing.reloadTimelines()
            entry = updated
            return true
        } catch {
            errorMessage = "Speichern fehlgeschlagen."
            return false
        }
    }

    func delete() async -> Bool {
        do {
            try await diaryRepository.delete(entryID: entry.id)
            widgetRefreshing.reloadTimelines()
            return true
        } catch {
            errorMessage = "Löschen fehlgeschlagen."
            return false
        }
    }
}
