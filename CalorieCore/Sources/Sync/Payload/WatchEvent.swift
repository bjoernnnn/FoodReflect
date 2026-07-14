import Foundation

/// Ein von der Watch ausgelöstes Ereignis, das per `transferUserInfo` ans iPhone geht
/// (puffert automatisch offline). **Idempotent**: `id` identifiziert das Event eindeutig,
/// doppelte Zustellung darf den Zustand nicht zweimal ändern (siehe `EventDeduplicator`).
public struct WatchEvent: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public var kind: Kind
    /// Zeitpunkt auf der Watch – maßgeblich für den DiaryEntry/WeightEntry.
    public var occurredAt: Date

    public enum Kind: Codable, Equatable, Sendable {
        case logWeight(weightKg: Double, creatine: Bool)
        case logQuick(reference: WatchQuickReference)
        /// Macht ein zuvor gesendetes `logQuick`/`logWeight` rückgängig (Undo-Toast).
        case revert(eventID: UUID)
    }

    public init(id: UUID, kind: Kind, occurredAt: Date) {
        self.id = id
        self.kind = kind
        self.occurredAt = occurredAt
    }
}
