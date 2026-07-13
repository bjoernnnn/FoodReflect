import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class DashboardViewModel {
    public private(set) var state: ViewState<DayTotals> = .loading
    public private(set) var todayEntries: [DiaryEntry] = []

    private let diaryRepository: any DiaryRepository
    private let goalsRepository: any GoalsRepository
    private let widgetRefreshing: any WidgetRefreshing
    private let calendar: Calendar

    public init(
        diaryRepository: any DiaryRepository,
        goalsRepository: any GoalsRepository,
        widgetRefreshing: any WidgetRefreshing,
        calendar: Calendar = .current
    ) {
        self.diaryRepository = diaryRepository
        self.goalsRepository = goalsRepository
        self.widgetRefreshing = widgetRefreshing
        self.calendar = calendar
    }

    private var todayKey: String {
        DayKey.make(for: Date(), calendar: calendar)
    }

    public func load() async {
        state = .loading
        do {
            // Ein Fetch für heutige Einträge, wiederverwendet für Liste + Totals
            // (statt ihn ein zweites Mal über eine volle UseCase-Instanz nachzuladen).
            let entries = try await diaryRepository.entries(on: todayKey)
            todayEntries = entries.sorted { $0.consumedAt > $1.consumedAt }
            let goals = try await goalsRepository.currentGoals() ?? GetDayTotalsUseCase.noGoals
            state = .loaded(GetDayTotalsUseCase.aggregate(dayKey: todayKey, entries: entries, goals: goals))
        } catch {
            state = .error(message: "Daten konnten nicht geladen werden.")
        }
    }

    public func delete(entryID: UUID) async {
        do {
            try await diaryRepository.delete(entryID: entryID)
            widgetRefreshing.reloadTimelines()
            await load()
        } catch {
            state = .error(message: "Löschen fehlgeschlagen.")
        }
    }
}
