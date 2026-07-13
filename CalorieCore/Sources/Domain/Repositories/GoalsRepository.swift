/// Persistenz für die aktuellen Ziele (ein aktiver Satz `MacroGoals`).
public protocol GoalsRepository: Sendable {
    func currentGoals() async throws(DomainError) -> MacroGoals?
    func save(_ goals: MacroGoals) async throws(DomainError)
}
