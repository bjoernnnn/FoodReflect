import Domain
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataMealTemplateRepository: MealTemplateRepository {
    public func all() async throws(DomainError) -> [MealTemplate] {
        let descriptor = FetchDescriptor<SDMealTemplate>(sortBy: [SortDescriptor(\.name)])
        do {
            return try modelContext.fetch(descriptor).map(MealTemplateMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func template(id: UUID) async throws(DomainError) -> MealTemplate? {
        let descriptor = FetchDescriptor<SDMealTemplate>(predicate: #Predicate { $0.id == id })
        do {
            return try modelContext.fetch(descriptor).first.map(MealTemplateMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ template: MealTemplate) async throws(DomainError) {
        let templateID = template.id
        let descriptor = FetchDescriptor<SDMealTemplate>(predicate: #Predicate { $0.id == templateID })
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                MealTemplateMapper.apply(template, to: existing)
            } else {
                modelContext.insert(MealTemplateMapper.toModel(template))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func delete(id: UUID) async throws(DomainError) {
        let descriptor = FetchDescriptor<SDMealTemplate>(predicate: #Predicate { $0.id == id })
        do {
            guard let existing = try modelContext.fetch(descriptor).first else { return }
            modelContext.delete(existing)
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
