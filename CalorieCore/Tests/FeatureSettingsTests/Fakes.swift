import Domain
import Foundation

final class FakeGoalsRepository: GoalsRepository, @unchecked Sendable {
    var goals: MacroGoals?
    var shouldThrow = false

    init(goals: MacroGoals? = nil) {
        self.goals = goals
    }

    func currentGoals() async throws(DomainError) -> MacroGoals? {
        if shouldThrow {
            throw DomainError.notFound
        }
        return goals
    }

    func save(_ goals: MacroGoals) async throws(DomainError) {
        if shouldThrow {
            throw DomainError.notFound
        }
        self.goals = goals
    }
}
