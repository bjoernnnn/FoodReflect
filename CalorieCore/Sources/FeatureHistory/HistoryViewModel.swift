import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class HistoryViewModel {
    public private(set) var state: ViewState<WeekStats> = .loading

    private let getWeekStats: GetWeekStatsUseCase
    private let calendar: Calendar

    public init(diaryRepository: any DiaryRepository, goalsRepository: any GoalsRepository, calendar: Calendar = .current) {
        getWeekStats = GetWeekStatsUseCase(diaryRepository: diaryRepository, goalsRepository: goalsRepository)
        self.calendar = calendar
    }

    /// `GetWeekStatsUseCase` ist trotz des Namens zeitraumagnostisch (nimmt beliebig viele
    /// `dayKeys`) – dieselbe UseCase bedient hier sowohl den Wochen- als auch den Monatsblick.
    public func load(days: Int) async {
        state = .loading
        do {
            let stats = try await getWeekStats(dayKeys: lastDayKeys(days))
            state = .loaded(stats)
        } catch {
            state = .error(message: "Verlauf konnte nicht geladen werden.")
        }
    }

    private func lastDayKeys(_ days: Int) -> [String] {
        (0 ..< days).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map { DayKey.make(for: $0, calendar: calendar) }
        }
    }
}
