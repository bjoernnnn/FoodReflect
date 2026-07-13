import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class WeightViewModel {
    public private(set) var state: ViewState<[WeightEntry]> = .loading
    public private(set) var trend: WeightTrend?

    private let weightRepository: any WeightRepository
    private let widgetRefreshing: any WidgetRefreshing
    private let calendar: Calendar

    public init(weightRepository: any WeightRepository, widgetRefreshing: any WidgetRefreshing, calendar: Calendar = .current) {
        self.weightRepository = weightRepository
        self.widgetRefreshing = widgetRefreshing
        self.calendar = calendar
    }

    /// Lädt standardmäßig die letzten 90 Tage – reicht für „Woche"/„Monat"/„Alle" im UI,
    /// ohne bei jedem Zeitraumwechsel neu vom Repository nachzuladen.
    public func load(daysBack: Int = 90) async {
        state = .loading
        let toKey = DayKey.make(for: Date(), calendar: calendar)
        let fromDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let fromKey = DayKey.make(for: fromDate, calendar: calendar)
        do {
            let entries = try await weightRepository.entries(fromDayKey: fromKey, toDayKey: toKey)
            let sorted = entries.sorted { $0.recordedAt < $1.recordedAt }
            trend = GetWeightTrendUseCase.aggregate(entries: sorted)
            state = sorted.isEmpty ? .empty : .loaded(sorted)
        } catch {
            state = .error(message: "Gewichtsdaten konnten nicht geladen werden.")
        }
    }

    public func save(weightKg: Double, date: Date) async {
        let entry = WeightEntry(dayKey: DayKey.make(for: date, calendar: calendar), weightKg: weightKg, recordedAt: date)
        do {
            try await weightRepository.save(entry)
            widgetRefreshing.reloadTimelines()
            await load()
        } catch {
            state = .error(message: "Speichern fehlgeschlagen. Bitte erneut versuchen.")
        }
    }

    public func delete(entryID: UUID) async {
        do {
            try await weightRepository.delete(entryID: entryID)
            widgetRefreshing.reloadTimelines()
            await load()
        } catch {
            state = .error(message: "Löschen fehlgeschlagen.")
        }
    }
}
