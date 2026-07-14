#if os(watchOS)
    import Foundation
    import Observation
    import WatchConnectivity

    /// Watch-Seite der Sync-Schicht. Empfängt den autoritativen `WatchSnapshot` per
    /// `didReceiveApplicationContext` (→ `snapshot` aktualisiert, Komplikationen neu geladen)
    /// und schickt Events per `transferUserInfo` (puffert automatisch offline).
    ///
    /// **Hardware-Hinweis:** Zustellung nur mit gekoppeltem iPhone verifizierbar. Der letzte
    /// Snapshot wird über `snapshotStore` im watch-internen Cache (App Group) gehalten, damit die
    /// App/Komplikationen auch offline etwas anzeigen.
    @Observable
    @MainActor
    public final class WatchSyncService: NSObject {
        /// Zuletzt bekannter autoritativer Zustand (oder der optimistische nach eigenem Event).
        public private(set) var snapshot: WatchSnapshot

        @ObservationIgnored private let snapshotStore: any SnapshotStore
        @ObservationIgnored private let onSnapshotChanged: @Sendable () -> Void
        @ObservationIgnored private let session: WCSession

        public init(
            snapshotStore: any SnapshotStore,
            onSnapshotChanged: @escaping @Sendable () -> Void = {},
            session: WCSession = .default
        ) {
            snapshot = snapshotStore.load() ?? .empty
            self.snapshotStore = snapshotStore
            self.onSnapshotChanged = onSnapshotChanged
            self.session = session
            super.init()
        }

        public func activate() {
            guard WCSession.isSupported() else { return }
            session.delegate = self
            session.activate()
        }

        /// Event → iPhone. `transferUserInfo` puffert automatisch, wenn gerade nicht erreichbar.
        public func send(_ event: WatchEvent) {
            guard let payload = try? SyncCoder.encode(event) else { return }
            session.transferUserInfo(payload)
        }

        /// Optimistisches lokales Update, bis der nächste autoritative Context vom iPhone kommt.
        public func applyOptimistic(_ transform: (inout WatchSnapshot) -> Void) {
            var next = snapshot
            transform(&next)
            update(next)
        }

        private func update(_ next: WatchSnapshot) {
            snapshot = next
            snapshotStore.save(next)
            onSnapshotChanged()
        }
    }

    extension WatchSyncService: WCSessionDelegate {
        public nonisolated func session(
            _: WCSession,
            activationDidCompleteWith _: WCSessionActivationState,
            error _: Error?
        ) {}

        public nonisolated func session(_: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
            guard let received = try? SyncCoder.decodeSnapshot(from: applicationContext) else { return }
            Task { @MainActor in self.update(received) }
        }
    }

    /// Persistiert den letzten Snapshot im watch-internen Cache (App Group). Default: In-Memory.
    public protocol SnapshotStore: Sendable {
        func load() -> WatchSnapshot?
        func save(_ snapshot: WatchSnapshot)
    }
#endif
