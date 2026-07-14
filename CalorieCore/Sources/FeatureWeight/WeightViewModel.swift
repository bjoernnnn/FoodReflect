import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class WeightViewModel {
    public private(set) var state: ViewState<[WeightEntry]> = .loading
    public private(set) var trend: WeightTrend?
    /// Geglättete Wochenmittel-Trendlinie für den Chart (leer bei < 1 Messung).
    public private(set) var weeklyAverages: [WeeklyWeightAverage] = []

    private let weightRepository: any WeightRepository
    private let widgetRefreshing: any WidgetRefreshing
    private let calendar: Calendar
    /// Merkt sich den zuletzt geladenen Zeitraum, damit `save`/`delete` denselben Ausschnitt neu
    /// laden statt ihn auf die 90-Tage-Vorgabe zurückzusetzen (relevant für `loadAll()`).
    private var lastDaysBack = 90
    private static let allDaysBack = 36500

    public init(weightRepository: any WeightRepository, widgetRefreshing: any WidgetRefreshing, calendar: Calendar = .current) {
        self.weightRepository = weightRepository
        self.widgetRefreshing = widgetRefreshing
        self.calendar = calendar
    }

    /// Lädt standardmäßig die letzten 90 Tage – reicht für „Woche"/„Monat"/„Alle" im UI,
    /// ohne bei jedem Zeitraumwechsel neu vom Repository nachzuladen.
    public func load(daysBack: Int = 90) async {
        lastDaysBack = daysBack
        state = .loading
        let toKey = DayKey.make(for: Date(), calendar: calendar)
        let fromDate = calendar.date(byAdding: .day, value: -daysBack, to: Date()) ?? Date()
        let fromKey = DayKey.make(for: fromDate, calendar: calendar)
        do {
            let entries = try await weightRepository.entries(fromDayKey: fromKey, toDayKey: toKey)
            let sorted = entries.sorted { $0.recordedAt < $1.recordedAt }
            trend = GetWeightTrendUseCase.aggregate(entries: sorted)
            weeklyAverages = GetWeightTrendUseCase.weeklyAverages(entries: sorted, calendar: calendar)
            state = sorted.isEmpty ? .empty : .loaded(sorted)
        } catch {
            state = .error(message: "Gewichtsdaten konnten nicht geladen werden.")
        }
    }

    /// Lädt faktisch die komplette Historie, für die vollständige Verlaufsseite (Phase 6).
    public func loadAll() async {
        await load(daysBack: Self.allDaysBack)
    }

    /// Ohne `entryID` wird eine neue Messung angelegt, mit `entryID` eine bestehende ersetzt
    /// (Repository macht Upsert-by-id).
    public func save(entryID: UUID? = nil, weightKg: Double, date: Date, withCreatine: Bool = false) async {
        let entry = WeightEntry(
            id: entryID ?? UUID(),
            dayKey: DayKey.make(for: date, calendar: calendar),
            weightKg: weightKg,
            recordedAt: date,
            withCreatine: withCreatine
        )
        do {
            try await weightRepository.save(entry)
            widgetRefreshing.reloadTimelines()
            await load(daysBack: lastDaysBack)
        } catch {
            state = .error(message: "Speichern fehlgeschlagen. Bitte erneut versuchen.")
        }
    }

    public func delete(entryID: UUID) async {
        do {
            try await weightRepository.delete(entryID: entryID)
            widgetRefreshing.reloadTimelines()
            await load(daysBack: lastDaysBack)
        } catch {
            state = .error(message: "Löschen fehlgeschlagen.")
        }
    }
}
