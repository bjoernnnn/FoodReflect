import Testing
@testable import Domain

@Suite("SuggestMacrosUseCase")
struct SuggestMacrosUseCaseTests {
    let sut = SuggestMacrosUseCase()

    @Test("2000 kcal ergibt 30/40/30-Aufteilung gerundet auf ganze Gramm")
    func standardSplit() {
        let goals = sut(dailyKcal: 2000)
        #expect(goals.dailyKcal == 2000)
        #expect(goals.proteinGrams == 150) // 2000*0.30/4 = 150
        #expect(goals.carbsGrams == 200) // 2000*0.40/4 = 200
        #expect(goals.fatGrams == 67) // 2000*0.30/9 = 66.67 -> 67
        #expect(goals.isCustomized == false)
    }

    @Test("Ziel 0 kcal ergibt 0 g für alle Makros, kein Crash")
    func zeroTarget() {
        let goals = sut(dailyKcal: 0)
        #expect(goals.proteinGrams == 0)
        #expect(goals.carbsGrams == 0)
        #expect(goals.fatGrams == 0)
    }

    @Test("Negatives Ziel wird auf 0 geklemmt statt negative Makros zu erzeugen")
    func negativeTargetClamped() {
        let goals = sut(dailyKcal: -500)
        #expect(goals.proteinGrams == 0)
        #expect(goals.carbsGrams == 0)
        #expect(goals.fatGrams == 0)
    }

    @Test("Krumme kcal-Werte runden korrekt (Randfall .5)")
    func roundingEdgeCase() {
        // 1000 * 0.30 / 9 = 33.33... -> 33
        let goals = sut(dailyKcal: 1000)
        #expect(goals.fatGrams == 33)
    }
}
