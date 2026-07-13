import Foundation
@testable import Domain

/// Framework-freier Test-Double – kein SwiftData. In-Memory-SwiftData-Tests der echten
/// Implementierung folgen in Phase 2 (DataTests).
final class InMemoryDiaryRepository: DiaryRepository, @unchecked Sendable {
    private(set) var storage: [DiaryEntry]

    init(entries: [DiaryEntry] = []) {
        storage = entries
    }

    func entries(on dayKey: String) async throws(DomainError) -> [DiaryEntry] {
        storage.filter { $0.dayKey == dayKey }
    }

    func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [DiaryEntry] {
        storage.filter { $0.dayKey >= fromDayKey && $0.dayKey <= toDayKey }
    }

    func save(_ entry: DiaryEntry) async throws(DomainError) {
        storage.append(entry)
    }

    func delete(entryID: UUID) async throws(DomainError) {
        storage.removeAll { $0.id == entryID }
    }
}
