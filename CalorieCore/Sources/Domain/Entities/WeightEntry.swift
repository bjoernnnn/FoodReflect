import Foundation

/// Eine Gewichtsmessung. `dayKey` erlaubt dieselbe Tages-/Bereichslogik wie beim
/// Kalorien-Tagebuch (siehe `DayKey`), `recordedAt` bleibt für Sortierung/Anzeige erhalten.
public struct WeightEntry: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var dayKey: String
    public var weightKg: Double
    public var recordedAt: Date
    /// Ob zum Messzeitpunkt Kreatin supplementiert wurde – Grundlage für die Auswertung
    /// „mit/ohne Kreatin" (Kreatin bindet Wasser, ≈ +1–2 kg). Standard `false`.
    public var withCreatine: Bool

    public init(
        id: UUID = UUID(),
        dayKey: String,
        weightKg: Double,
        recordedAt: Date,
        withCreatine: Bool = false
    ) {
        self.id = id
        self.dayKey = dayKey
        self.weightKg = weightKg
        self.recordedAt = recordedAt
        self.withCreatine = withCreatine
    }
}
