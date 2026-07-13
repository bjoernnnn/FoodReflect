@testable import Domain

final class InMemoryGoalsRepository: GoalsRepository, @unchecked Sendable {
    private(set) var goals: MacroGoals?

    init(goals: MacroGoals? = nil) {
        self.goals = goals
    }

    func currentGoals() async throws(DomainError) -> MacroGoals? {
        goals
    }

    func save(_ goals: MacroGoals) async throws(DomainError) {
        self.goals = goals
    }
}
