import Foundation

/// Persistenz für Gewichtsmessungen. Implementiert in `Data` via SwiftData.
public protocol WeightRepository: Sendable {
    func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [WeightEntry]
    func latest() async throws(DomainError) -> WeightEntry?
    func save(_ entry: WeightEntry) async throws(DomainError)
    func delete(entryID: UUID) async throws(DomainError)
}
