import Foundation

/// Persistenz für Tagebucheinträge. Implementiert in `Data` via SwiftData.
public protocol DiaryRepository: Sendable {
    func entries(on dayKey: String) async throws(DomainError) -> [DiaryEntry]
    func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [DiaryEntry]
    func save(_ entry: DiaryEntry) async throws(DomainError)
    func delete(entryID: UUID) async throws(DomainError)
}
