import Foundation
@testable import Domain

final class InMemoryWeightRepository: WeightRepository, @unchecked Sendable {
    private(set) var storage: [WeightEntry]

    init(entries: [WeightEntry] = []) {
        storage = entries
    }

    func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [WeightEntry] {
        storage.filter { $0.dayKey >= fromDayKey && $0.dayKey <= toDayKey }
    }

    func latest() async throws(DomainError) -> WeightEntry? {
        storage.max { $0.recordedAt < $1.recordedAt }
    }

    func save(_ entry: WeightEntry) async throws(DomainError) {
        storage.removeAll { $0.id == entry.id }
        storage.append(entry)
    }

    func delete(entryID: UUID) async throws(DomainError) {
        storage.removeAll { $0.id == entryID }
    }
}
