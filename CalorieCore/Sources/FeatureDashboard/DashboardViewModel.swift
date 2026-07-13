import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class DashboardViewModel {
    public private(set) var state: ViewState<DayTotals> = .loading
    public private(set) var todayEntries: [DiaryEntry] = []

    private let diaryRepository: any DiaryRepository
    private let getDayTotals: GetDayTotalsUseCase
    private let calendar: Calendar

    public init(diaryRepository: any DiaryRepository, goalsRepository: any GoalsRepository, calendar: Calendar = .current) {
        self.diaryRepository = diaryRepository
        getDayTotals = GetDayTotalsUseCase(diaryRepository: diaryRepository, goalsRepository: goalsRepository)
        self.calendar = calendar
    }

    private var todayKey: String {
        DayKey.make(for: Date(), calendar: calendar)
    }

    public func load() async {
        state = .loading
        do {
            let entries = try await diaryRepository.entries(on: todayKey)
            todayEntries = entries.sorted { $0.consumedAt > $1.consumedAt }
            state = try await .loaded(getDayTotals(dayKey: todayKey))
        } catch {
            state = .error(message: "Daten konnten nicht geladen werden.")
        }
    }

    public func delete(entryID: UUID) async {
        do {
            try await diaryRepository.delete(entryID: entryID)
            await load()
        } catch {
            state = .error(message: "Löschen fehlgeschlagen.")
        }
    }
}
