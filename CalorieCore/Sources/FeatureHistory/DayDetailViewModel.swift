import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
final class DayDetailViewModel {
    private(set) var state: ViewState<DayTotals> = .loading
    private(set) var entries: [DiaryEntry] = []

    let dayKey: String
    private let diaryRepository: any DiaryRepository
    private let goalsRepository: any GoalsRepository

    init(dayKey: String, diaryRepository: any DiaryRepository, goalsRepository: any GoalsRepository) {
        self.dayKey = dayKey
        self.diaryRepository = diaryRepository
        self.goalsRepository = goalsRepository
    }

    func load() async {
        state = .loading
        do {
            let fetchedEntries = try await diaryRepository.entries(on: dayKey)
            entries = fetchedEntries.sorted { $0.consumedAt < $1.consumedAt }
            let goals = try await goalsRepository.currentGoals() ?? GetDayTotalsUseCase.noGoals
            let totals = GetDayTotalsUseCase.aggregate(dayKey: dayKey, entries: fetchedEntries, goals: goals)
            state = entries.isEmpty ? .empty : .loaded(totals)
        } catch {
            state = .error(message: "Tagesdetails konnten nicht geladen werden.")
        }
    }
}
