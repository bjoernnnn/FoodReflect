import Domain
import Foundation

@Observable
@MainActor
public final class OnboardingViewModel {
    public var dailyKcalInput: String = "2000"
    public private(set) var isSaving = false
    public private(set) var errorMessage: String?
    public private(set) var didCompleteOnboarding = false

    private let goalsRepository: any GoalsRepository
    private let suggestMacros = SuggestMacrosUseCase()

    public init(goalsRepository: any GoalsRepository) {
        self.goalsRepository = goalsRepository
    }

    public var dailyKcal: Int {
        Int(dailyKcalInput) ?? 0
    }

    public var suggestedGoals: MacroGoals {
        suggestMacros(dailyKcal: dailyKcal)
    }

    public var canConfirm: Bool {
        dailyKcal > 0
    }

    public func confirm() async {
        guard canConfirm else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await goalsRepository.save(suggestedGoals)
            didCompleteOnboarding = true
        } catch {
            errorMessage = "Speichern fehlgeschlagen. Bitte erneut versuchen."
        }
        isSaving = false
    }
}
