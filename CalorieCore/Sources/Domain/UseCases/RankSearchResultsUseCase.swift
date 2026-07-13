/// Zusätzliche, nicht in `Food` gespeicherte Signale eines Suchtreffers (z. B. aus Open Food Facts),
/// die nur für das Ranking benötigt werden.
public struct SearchRankingHints: Equatable, Sendable {
    public var localeMatch: Bool
    public var popularity: Double

    public init(localeMatch: Bool = false, popularity: Double = 0) {
        self.localeMatch = localeMatch
        self.popularity = popularity
    }
}

public struct SearchCandidate: Equatable, Sendable {
    public var food: Food
    public var hints: SearchRankingHints

    public init(food: Food, hints: SearchRankingHints = .init()) {
        self.food = food
        self.hints = hints
    }
}

/// Sortiert Suchtreffer nach: (1) Vollständigkeit der Nährwerte, (2) Sprach-/Landesmatch,
/// (3) OFF-Popularität, (4) eigene `useCount`.
public struct RankSearchResultsUseCase: Sendable {
    public init() {}

    public func callAsFunction(_ candidates: [SearchCandidate]) -> [Food] {
        candidates
            .sorted(by: Self.isRankedHigher)
            .map(\.food)
    }

    private static func isRankedHigher(_ lhs: SearchCandidate, _ rhs: SearchCandidate) -> Bool {
        let lhsCompleteness = completeness(of: lhs.food)
        let rhsCompleteness = completeness(of: rhs.food)
        if lhsCompleteness != rhsCompleteness {
            return lhsCompleteness > rhsCompleteness
        }
        if lhs.hints.localeMatch != rhs.hints.localeMatch {
            return lhs.hints.localeMatch
        }
        if lhs.hints.popularity != rhs.hints.popularity {
            return lhs.hints.popularity > rhs.hints.popularity
        }
        return lhs.food.useCount > rhs.food.useCount
    }

    private static func completeness(of food: Food) -> Int {
        [food.kcalPer100g, food.proteinPer100g, food.carbsPer100g, food.fatPer100g]
            .filter { $0 > 0 }
            .count
    }
}
