import Domain
import SwiftData

/// Es wird zur Laufzeit maximal eine `SDGoals`-Zeile gehalten (der aktive Zielsatz).
@ModelActor
public actor SwiftDataGoalsRepository: GoalsRepository {
    public func currentGoals() async throws(DomainError) -> MacroGoals? {
        do {
            return try modelContext.fetch(FetchDescriptor<SDGoals>()).first.map(GoalsMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ goals: MacroGoals) async throws(DomainError) {
        do {
            if let existing = try modelContext.fetch(FetchDescriptor<SDGoals>()).first {
                GoalsMapper.update(existing, from: goals)
            } else {
                modelContext.insert(GoalsMapper.toModel(goals))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
