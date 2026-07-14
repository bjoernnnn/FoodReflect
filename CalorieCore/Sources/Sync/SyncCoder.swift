import Foundation

/// Versioniert und (de)serialisiert Sync-Payloads für WatchConnectivity.
///
/// WCSession (`updateApplicationContext` / `transferUserInfo`) erwartet property-list-fähige
/// `[String: Any]`-Dictionaries. Wir kodieren die typisierten DTOs zu `Data` (JSON) und legen
/// sie zusammen mit `schemaVersion` in ein flaches Dictionary. Beim Dekodieren werden unbekannte
/// (neuere) Versionen **ignoriert** statt zu crashen – Vorwärtskompatibilität.
public enum SyncCoder {
    /// Aktuelle Schema-Version. Bei inkompatiblen Änderungen erhöhen.
    public static let schemaVersion = 1

    static let versionKey = "schemaVersion"
    static let payloadKey = "payload"

    public enum CoderError: Error, Equatable {
        /// Version fehlt, ist älter/neuer als unterstützt, oder Payload fehlt.
        case unsupportedVersion(Int?)
        case malformedPayload
    }

    // MARK: - Encode

    public static func encode(_ snapshot: WatchSnapshot) throws -> [String: Any] {
        try envelope(for: snapshot)
    }

    public static func encode(_ event: WatchEvent) throws -> [String: Any] {
        try envelope(for: event)
    }

    private static func envelope(for value: some Encodable) throws -> [String: Any] {
        let data = try JSONEncoder().encode(value)
        return [versionKey: schemaVersion, payloadKey: data]
    }

    // MARK: - Decode

    public static func decodeSnapshot(from dictionary: [String: Any]) throws -> WatchSnapshot {
        try decode(WatchSnapshot.self, from: dictionary)
    }

    public static func decodeEvent(from dictionary: [String: Any]) throws -> WatchEvent {
        try decode(WatchEvent.self, from: dictionary)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        let version = dictionary[versionKey] as? Int
        guard version == schemaVersion else {
            throw CoderError.unsupportedVersion(version)
        }
        guard let data = dictionary[payloadKey] as? Data else {
            throw CoderError.malformedPayload
        }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw CoderError.malformedPayload
        }
    }
}
