import Testing
@testable import Domain

@Suite("RankSearchResultsUseCase")
struct RankSearchResultsUseCaseTests {
    let sut = RankSearchResultsUseCase()

    private func food(
        _ name: String,
        kcal: Double = 100,
        protein: Double = 5,
        carbs: Double = 5,
        fat: Double = 5,
        useCount: Int = 0
    ) -> Food {
        Food(
            name: name,
            kcalPer100g: kcal,
            proteinPer100g: protein,
            carbsPer100g: carbs,
            fatPer100g: fat,
            source: .manual,
            useCount: useCount
        )
    }

    @Test("Vollständige Nährwerte schlagen unvollständige, unabhängig von Popularität")
    func completenessBeatsPopularity() {
        let complete = food("Komplett")
        let incomplete = food("Unvollständig", protein: 0, carbs: 0, fat: 0)
        let candidates = [
            SearchCandidate(food: incomplete, hints: .init(popularity: 1000)),
            SearchCandidate(food: complete, hints: .init(popularity: 0))
        ]
        let ranked = sut(candidates)
        #expect(ranked.first?.name == "Komplett")
    }

    @Test("Bei gleicher Vollständigkeit gewinnt Sprach-/Landesmatch")
    func localeMatchWinsOnTie() {
        let match = food("Match")
        let noMatch = food("KeinMatch")
        let candidates = [
            SearchCandidate(food: noMatch, hints: .init(localeMatch: false, popularity: 100)),
            SearchCandidate(food: match, hints: .init(localeMatch: true, popularity: 0))
        ]
        let ranked = sut(candidates)
        #expect(ranked.first?.name == "Match")
    }

    @Test("Bei Gleichstand sonst entscheidet OFF-Popularität")
    func popularityWinsOnFurtherTie() {
        let popular = food("Populär")
        let unpopular = food("Unpopulär")
        let candidates = [
            SearchCandidate(food: unpopular, hints: .init(popularity: 1)),
            SearchCandidate(food: popular, hints: .init(popularity: 100))
        ]
        let ranked = sut(candidates)
        #expect(ranked.first?.name == "Populär")
    }

    @Test("Letztes Kriterium: eigene useCount")
    func useCountIsLastTiebreaker() {
        let usedOften = food("Oft genutzt", useCount: 10)
        let usedRarely = food("Selten genutzt", useCount: 0)
        let candidates = [
            SearchCandidate(food: usedRarely),
            SearchCandidate(food: usedOften)
        ]
        let ranked = sut(candidates)
        #expect(ranked.first?.name == "Oft genutzt")
    }

    @Test("Leere Liste crasht nicht")
    func emptyList() {
        #expect(sut([]).isEmpty)
    }
}
