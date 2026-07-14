import Foundation

/// Persistiert die IDs bereits verarbeiteter Watch-Events, damit Doppel-Zustellung
/// (WatchConnectivity kann `transferUserInfo` mehrfach liefern) den Zustand nicht
/// zweimal ändert.
public protocol ProcessedEventStore: Sendable {
    func contains(_ id: UUID) -> Bool
    func insert(_ id: UUID)
}

/// Idempotenz-Gate: `shouldProcess` gibt genau **einmal pro Event-ID** `true` zurück.
/// Jede weitere Zustellung derselben ID liefert `false`.
public struct EventDeduplicator: Sendable {
    private let store: any ProcessedEventStore

    public init(store: any ProcessedEventStore) {
        self.store = store
    }

    /// `true`, wenn das Event neu ist (und markiert es sofort als verarbeitet);
    /// `false` bei Duplikat.
    @discardableResult
    public func shouldProcess(_ event: WatchEvent) -> Bool {
        guard !store.contains(event.id) else { return false }
        store.insert(event.id)
        return true
    }
}

/// In-Memory-Standard (Watch-Cache bzw. Tests). Thread-safe über eine Lock.
public final class InMemoryProcessedEventStore: ProcessedEventStore, @unchecked Sendable {
    private var ids: Set<UUID>
    private let lock = NSLock()

    public init(ids: Set<UUID> = []) {
        self.ids = ids
    }

    public func contains(_ id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return ids.contains(id)
    }

    public func insert(_ id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        ids.insert(id)
    }
}
