import Foundation

/// Persistenz der Gerichte/Mahlzeiten-Vorlagen. CRUD, alle async und typisiert fehlerbehaftet.
public protocol MealTemplateRepository: Sendable {
    func all() async throws(DomainError) -> [MealTemplate]
    func template(id: UUID) async throws(DomainError) -> MealTemplate?
    func save(_ template: MealTemplate) async throws(DomainError)
    func delete(id: UUID) async throws(DomainError)
}
