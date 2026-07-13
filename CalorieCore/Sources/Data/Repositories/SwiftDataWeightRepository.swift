import Domain
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataWeightRepository: WeightRepository {
    public func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [WeightEntry] {
        let descriptor = FetchDescriptor<SDWeightEntry>(
            predicate: #Predicate { $0.dayKey >= fromDayKey && $0.dayKey <= toDayKey },
            sortBy: [SortDescriptor(\.recordedAt)]
        )
        do {
            return try modelContext.fetch(descriptor).map(WeightEntryMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func latest() async throws(DomainError) -> WeightEntry? {
        var descriptor = FetchDescriptor<SDWeightEntry>(sortBy: [SortDescriptor(\.recordedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        do {
            return try modelContext.fetch(descriptor).first.map(WeightEntryMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ entry: WeightEntry) async throws(DomainError) {
        let entryID = entry.id
        let descriptor = FetchDescriptor<SDWeightEntry>(predicate: #Predicate { $0.id == entryID })
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                existing.dayKey = entry.dayKey
                existing.weightKg = entry.weightKg
                existing.recordedAt = entry.recordedAt
            } else {
                modelContext.insert(WeightEntryMapper.toModel(entry))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func delete(entryID: UUID) async throws(DomainError) {
        let descriptor = FetchDescriptor<SDWeightEntry>(predicate: #Predicate { $0.id == entryID })
        do {
            guard let existing = try modelContext.fetch(descriptor).first else { return }
            modelContext.delete(existing)
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
