import Foundation

/// Mahlzeitentyp eines Tagebucheintrags. `String`-Raw für stabile Persistenz (SwiftData/CloudKit),
/// `Codable` für die WatchConnectivity-Payload (siehe Block C).
public enum MealType: String, Codable, Sendable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    public var id: String {
        rawValue
    }

    /// Leitet den Mahlzeitentyp aus der Uhrzeit ab: <11 Uhr Frühstück, <15 Mittag, <21 Abend, sonst Snack.
    /// Bewusst überschreibbar – die abgeleitete Wahl ist nur die Vorbelegung im Log-Sheet.
    public static func make(for date: Date, calendar: Calendar = .current) -> MealType {
        switch calendar.component(.hour, from: date) {
        case ..<11: .breakfast
        case ..<15: .lunch
        case ..<21: .dinner
        default: .snack
        }
    }

    /// Deutscher Anzeigename (Domain bleibt framework-frei; UI nutzt diesen String direkt).
    public var displayName: String {
        switch self {
        case .breakfast: "Frühstück"
        case .lunch: "Mittag"
        case .dinner: "Abend"
        case .snack: "Snack"
        }
    }

    /// SF-Symbol-Name für die konsistente Darstellung über App, Widget und Watch hinweg.
    public var iconSystemName: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "sunset"
        case .snack: "moon"
        }
    }

    /// Feste Sortierreihenfolge für Mahlzeiten-Abschnitte (Frühstück → Snack), unabhängig von der Uhrzeit.
    public var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        case .snack: 3
        }
    }
}
