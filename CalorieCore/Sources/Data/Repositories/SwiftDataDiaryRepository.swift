import Domain
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataDiaryRepository: DiaryRepository {
    public func entries(on dayKey: String) async throws(DomainError) -> [DiaryEntry] {
        let descriptor = FetchDescriptor<SDDiaryEntry>(
            predicate: #Predicate { $0.dayKey == dayKey },
            sortBy: [SortDescriptor(\.consumedAt)]
        )
        do {
            return try modelContext.fetch(descriptor).map(DiaryEntryMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [DiaryEntry] {
        let descriptor = FetchDescriptor<SDDiaryEntry>(
            predicate: #Predicate { $0.dayKey >= fromDayKey && $0.dayKey <= toDayKey },
            sortBy: [SortDescriptor(\.consumedAt)]
        )
        do {
            return try modelContext.fetch(descriptor).map(DiaryEntryMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ entry: DiaryEntry) async throws(DomainError) {
        let entryID = entry.id
        let descriptor = FetchDescriptor<SDDiaryEntry>(predicate: #Predicate { $0.id == entryID })
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                existing.consumedAt = entry.consumedAt
                existing.dayKey = entry.dayKey
                existing.foodName = entry.foodName
                existing.amountGrams = entry.amountGrams
                existing.kcal = entry.kcal
                existing.protein = entry.protein
                existing.carbs = entry.carbs
                existing.fat = entry.fat
                existing.foodID = entry.foodID
            } else {
                modelContext.insert(DiaryEntryMapper.toModel(entry))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func delete(entryID: UUID) async throws(DomainError) {
        let descriptor = FetchDescriptor<SDDiaryEntry>(predicate: #Predicate { $0.id == entryID })
        do {
            guard let existing = try modelContext.fetch(descriptor).first else { return }
            modelContext.delete(existing)
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
