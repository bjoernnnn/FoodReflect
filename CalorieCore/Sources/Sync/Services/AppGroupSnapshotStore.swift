#if os(watchOS)
    import Foundation

    /// Persistiert den letzten `WatchSnapshot` im watch-internen App-Group-Container, damit sowohl
    /// die Watch-App (schreibt beim Context-Empfang) als auch die Komplikationen (lesen beim
    /// Timeline-Aufbau) offline denselben Zustand sehen. Klein genug für `UserDefaults`.
    public struct AppGroupSnapshotStore: SnapshotStore {
        private let defaults: UserDefaults?
        private let key = "watchSnapshot.v1"

        /// `suiteName` = watch-interne App-Group-ID. Ohne funktionierende App Group (z. B. Preview)
        /// fällt der Store still auf „kein Cache" zurück, statt zu crashen.
        public init(suiteName: String) {
            defaults = UserDefaults(suiteName: suiteName)
        }

        public func load() -> WatchSnapshot? {
            guard let data = defaults?.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(WatchSnapshot.self, from: data)
        }

        public func save(_ snapshot: WatchSnapshot) {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            defaults?.set(data, forKey: key)
        }
    }
#endif
