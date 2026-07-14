import Foundation

/// Gleitender Durchschnitt + Delta zur vorherigen Messung über einen Zeitraum, analog zu
/// `GetWeekStatsUseCase` für Kalorien.
public struct GetWeightTrendUseCase: Sendable {
    private let weightRepository: any WeightRepository

    public init(weightRepository: any WeightRepository) {
        self.weightRepository = weightRepository
    }

    public func callAsFunction(fromDayKey: String, toDayKey: String) async throws(DomainError) -> WeightTrend {
        let entries = try await weightRepository.entries(fromDayKey: fromDayKey, toDayKey: toDayKey)
        return Self.aggregate(entries: entries)
    }

    /// Reine Aggregationslogik, unabhängig vom Repository testbar.
    public static func aggregate(entries: [WeightEntry]) -> WeightTrend {
        let sorted = entries.sorted { $0.recordedAt < $1.recordedAt }
        guard let latest = sorted.last else {
            return WeightTrend(latest: nil, averageWeightKg: nil, deltaFromPreviousMeasurement: nil)
        }
        let average = sorted.reduce(0.0) { $0 + $1.weightKg } / Double(sorted.count)
        let previous = sorted.dropLast().last
        let delta = previous.map { latest.weightKg - $0.weightKg }
        return WeightTrend(latest: latest, averageWeightKg: average, deltaFromPreviousMeasurement: delta)
    }

    /// Wochenmittel je Kalenderwoche (aufsteigend nach Wochenstart) – für die geglättete
    /// Trendlinie im Chart. Reine Funktion, unabhängig vom Repository testbar.
    public static func weeklyAverages(entries: [WeightEntry], calendar: Calendar = .current) -> [WeeklyWeightAverage] {
        let groups = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .weekOfYear, for: entry.recordedAt)?.start ?? entry.recordedAt
        }
        return groups
            .map { weekStart, group in
                WeeklyWeightAverage(
                    weekStart: weekStart,
                    averageKg: group.reduce(0.0) { $0 + $1.weightKg } / Double(group.count)
                )
            }
            .sorted { $0.weekStart < $1.weekStart }
    }
}
