import Foundation

/// Eine Gewichtsmessung. `dayKey` erlaubt dieselbe Tages-/Bereichslogik wie beim
/// Kalorien-Tagebuch (siehe `DayKey`), `recordedAt` bleibt für Sortierung/Anzeige erhalten.
public struct WeightEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var dayKey: String
    public var weightKg: Double
    public var recordedAt: Date

    public init(
        id: UUID = UUID(),
        dayKey: String,
        weightKg: Double,
        recordedAt: Date
    ) {
        self.id = id
        self.dayKey = dayKey
        self.weightKg = weightKg
        self.recordedAt = recordedAt
    }
}
