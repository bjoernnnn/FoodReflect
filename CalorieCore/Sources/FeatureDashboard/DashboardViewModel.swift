import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class DashboardViewModel {
    public private(set) var state: ViewState<DayTotals> = .loading
    public private(set) var todayEntries: [DiaryEntry] = []
    public private(set) var weekStats: WeekStats?

    private let diaryRepository: any DiaryRepository
    private let goalsRepository: any GoalsRepository
    private let widgetRefreshing: any WidgetRefreshing
    private let getWeekStats: GetWeekStatsUseCase
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
        getWeekStats = GetWeekStatsUseCase(diaryRepository: diaryRepository, goalsRepository: goalsRepository)
        self.calendar = calendar
    }

    private var todayKey: String {
        DayKey.make(for: Date(), calendar: calendar)
    }

    private func last7DayKeys() -> [String] {
        (0 ..< 7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map { DayKey.make(for: $0, calendar: calendar) }
        }
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
        weekStats = try? await getWeekStats(dayKeys: last7DayKeys())
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
