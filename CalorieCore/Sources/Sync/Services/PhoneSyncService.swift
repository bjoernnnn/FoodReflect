#if os(iOS)
    import Foundation
    import WatchConnectivity

    /// iPhone-Seite der Sync-Schicht. Pusht den autoritativen `WatchSnapshot` per
    /// `updateApplicationContext` und empfängt Watch-Events per `didReceiveUserInfo`.
    ///
    /// **Hardware-Hinweis:** Die tatsächliche Zustellung ist nur mit gekoppelter Apple Watch
    /// verifizierbar. Kodierung/Dekodierung (`SyncCoder`), Idempotenz (`EventDeduplicator`) und
    /// Mapping sind davon entkoppelt und in `SyncTests` abgedeckt.
    public final class PhoneSyncService: NSObject, @unchecked Sendable {
        /// Wird für jedes **neue** (nicht duplizierte) Watch-Event aufgerufen. Die App verdrahtet
        /// hier ihre Repositories/UseCases und pusht danach einen frischen Snapshot.
        public typealias EventHandler = @Sendable (WatchEvent) async -> Void

        private let deduplicator: EventDeduplicator
        private let onEvent: EventHandler
        private let session: WCSession

        public init(
            processedEventStore: any ProcessedEventStore,
            onEvent: @escaping EventHandler,
            session: WCSession = .default
        ) {
            deduplicator = EventDeduplicator(store: processedEventStore)
            self.onEvent = onEvent
            self.session = session
            super.init()
        }

        public func activate() {
            guard WCSession.isSupported() else { return }
            session.delegate = self
            session.activate()
        }

        /// Autoritativer Zustand → Watch. Idempotent auf WCSession-Ebene (überschreibt den Context).
        public func push(_ snapshot: WatchSnapshot) {
            guard session.activationState == .activated else { return }
            guard let context = try? SyncCoder.encode(snapshot) else { return }
            try? session.updateApplicationContext(context)
        }
    }

    extension PhoneSyncService: WCSessionDelegate {
        public func session(_: WCSession, activationDidCompleteWith _: WCSessionActivationState, error _: Error?) {}

        public func sessionDidBecomeInactive(_: WCSession) {}

        public func sessionDidDeactivate(_: WCSession) {
            // Nach Deaktivierung (z. B. Watch-Wechsel) erneut aktivieren.
            session.activate()
        }

        public func session(_: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
            guard let event = try? SyncCoder.decodeEvent(from: userInfo) else { return }
            guard deduplicator.shouldProcess(event) else { return }
            let handler = onEvent
            Task { await handler(event) }
        }
    }
#endif
