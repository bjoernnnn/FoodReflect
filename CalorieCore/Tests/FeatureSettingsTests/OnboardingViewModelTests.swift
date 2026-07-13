import Testing
@testable import Domain
@testable import FeatureSettings

@Suite("OnboardingViewModel")
@MainActor
struct OnboardingViewModelTests {
    @Test("Bestätigen speichert den 30/40/30-Vorschlag und markiert Onboarding als abgeschlossen")
    func confirmSavesGoals() async {
        let repository = FakeGoalsRepository()
        let sut = OnboardingViewModel(goalsRepository: repository)
        sut.dailyKcalInput = "2000"

        await sut.confirm()

        #expect(sut.didCompleteOnboarding)
        #expect(repository.goals?.dailyKcal == 2000)
        #expect(repository.goals?.proteinGrams == 150)
        #expect(repository.goals?.isCustomized == false)
    }

    @Test("Leere/ungültige Eingabe verhindert das Bestätigen")
    func invalidInputCannotConfirm() async {
        let repository = FakeGoalsRepository()
        let sut = OnboardingViewModel(goalsRepository: repository)
        sut.dailyKcalInput = "abc"

        #expect(sut.canConfirm == false)
        await sut.confirm()
        #expect(sut.didCompleteOnboarding == false)
        #expect(repository.goals == nil)
    }

    @Test("Fehler beim Speichern wird als errorMessage exponiert, kein Crash")
    func saveFailureSurfacesErrorMessage() async {
        let repository = FakeGoalsRepository()
        repository.shouldThrow = true
        let sut = OnboardingViewModel(goalsRepository: repository)
        sut.dailyKcalInput = "2000"

        await sut.confirm()

        #expect(sut.didCompleteOnboarding == false)
        #expect(sut.errorMessage != nil)
    }
}
