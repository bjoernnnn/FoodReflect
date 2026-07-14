import Foundation

/// Zusammenfassung eines Gewichts-Zeitraums für die Gewichts-Ansicht.
public struct WeightTrend: Equatable, Sendable {
    public var latest: WeightEntry?
    public var averageWeightKg: Double?
    /// Differenz zur vorherigen Messung (negativ = abgenommen). `nil` bei weniger als 2 Messungen.
    public var deltaFromPreviousMeasurement: Double?

    public init(latest: WeightEntry?, averageWeightKg: Double?, deltaFromPreviousMeasurement: Double?) {
        self.latest = latest
        self.averageWeightKg = averageWeightKg
        self.deltaFromPreviousMeasurement = deltaFromPreviousMeasurement
    }
}

/// Ein Wochenmittel der Gewichtsmessungen – glättet das tägliche Rauschen (z. B. Wasser) für
/// eine ruhigere Trendlinie im Chart.
public struct WeeklyWeightAverage: Equatable, Sendable, Identifiable {
    public let weekStart: Date
    public let averageKg: Double
    public var id: Date {
        weekStart
    }

    public init(weekStart: Date, averageKg: Double) {
        self.weekStart = weekStart
        self.averageKg = averageKg
    }
}
