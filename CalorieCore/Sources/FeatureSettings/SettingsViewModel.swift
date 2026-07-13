import DesignSystem
import Domain
import Foundation

@Observable
@MainActor
public final class SettingsViewModel {
    public private(set) var state: ViewState<MacroGoals> = .loading

    private let goalsRepository: any GoalsRepository
    private let suggestMacros = SuggestMacrosUseCase()

    public init(goalsRepository: any GoalsRepository) {
        self.goalsRepository = goalsRepository
    }

    public func load() async {
        state = .loading
        do {
            guard let goals = try await goalsRepository.currentGoals() else {
                state = .empty
                return
            }
            state = .loaded(goals)
        } catch {
            state = .error(message: "Ziele konnten nicht geladen werden.")
        }
    }

    public func save(dailyKcal: Int, proteinGrams: Int, carbsGrams: Int, fatGrams: Int) async {
        let goals = MacroGoals(
            dailyKcal: dailyKcal, proteinGrams: proteinGrams, carbsGrams: carbsGrams, fatGrams: fatGrams,
            isCustomized: true
        )
        await persist(goals)
    }

    public func restoreAutoSuggestion(dailyKcal: Int) async {
        await persist(suggestMacros(dailyKcal: dailyKcal))
    }

    private func persist(_ goals: MacroGoals) async {
        do {
            try await goalsRepository.save(goals)
            state = .loaded(goals)
        } catch {
            state = .error(message: "Speichern fehlgeschlagen. Bitte erneut versuchen.")
        }
    }
}
