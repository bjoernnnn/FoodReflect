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
