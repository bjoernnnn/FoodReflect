/// Wochenzusammenfassung für die Dashboard-Karte.
public struct WeekStats: Equatable, Sendable {
    public var days: [DayTotals]
    public var averageKcal: Double
    /// Negativ = im Schnitt unter Ziel, positiv = über Ziel.
    public var deltaFromGoal: Double

    public init(days: [DayTotals], averageKcal: Double, deltaFromGoal: Double) {
        self.days = days
        self.averageKcal = averageKcal
        self.deltaFromGoal = deltaFromGoal
    }
}
