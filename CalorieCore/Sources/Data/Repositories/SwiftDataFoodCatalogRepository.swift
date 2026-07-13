import Domain
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataFoodCatalogRepository: FoodCatalogRepository {
    public func food(barcode: String) async throws(DomainError) -> Food? {
        let descriptor = FetchDescriptor<SDFood>(predicate: #Predicate { $0.barcode == barcode })
        do {
            return try modelContext.fetch(descriptor).first.map(FoodMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    /// Filtert im Speicher statt per `#Predicate`, um case-insensitive Teiltreffer
    /// portabel zu halten (kleiner lokaler Katalog-Cache, keine Performance-Sorge).
    public func search(localQuery query: String) async throws(DomainError) -> [Food] {
        do {
            let all = try modelContext.fetch(FetchDescriptor<SDFood>())
            return all
                .filter {
                    $0.name.localizedCaseInsensitiveContains(query)
                        || ($0.brand?.localizedCaseInsensitiveContains(query) ?? false)
                }
                .map(FoodMapper.toDomain)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ food: Food) async throws(DomainError) {
        let foodID = food.id
        let descriptor = FetchDescriptor<SDFood>(predicate: #Predicate { $0.id == foodID })
        do {
            if let existing = try modelContext.fetch(descriptor).first {
                FoodMapper.update(existing, from: food)
            } else {
                modelContext.insert(FoodMapper.toModel(food))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func recordUsage(foodID: UUID, at date: Date) async throws(DomainError) {
        let descriptor = FetchDescriptor<SDFood>(predicate: #Predicate { $0.id == foodID })
        do {
            guard let existing = try modelContext.fetch(descriptor).first else {
                throw DomainError.notFound
            }
            existing.lastUsedAt = date
            existing.useCount += 1
            try modelContext.save()
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
