import Foundation
@testable import Domain

final class InMemoryMealTemplateRepository: MealTemplateRepository, @unchecked Sendable {
    private(set) var storage: [MealTemplate]

    init(templates: [MealTemplate] = []) {
        storage = templates
    }

    func all() async throws(DomainError) -> [MealTemplate] {
        storage
    }

    func template(id: UUID) async throws(DomainError) -> MealTemplate? {
        storage.first { $0.id == id }
    }

    func save(_ template: MealTemplate) async throws(DomainError) {
        storage.removeAll { $0.id == template.id }
        storage.append(template)
    }

    func delete(id: UUID) async throws(DomainError) {
        storage.removeAll { $0.id == id }
    }
}
