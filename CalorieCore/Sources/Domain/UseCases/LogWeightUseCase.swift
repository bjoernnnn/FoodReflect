import Foundation

/// Speichert eine neue Gewichtsmessung. Ist `withCreatine == nil`, wird der Kreatin-Status
/// der letzten Messung übernommen (Default `false`, falls noch keine existiert) – so muss der
/// Nutzer den Toggle nur ändern, wenn sich etwas geändert hat (Watch-Komfort, Abschnitt 4).
public struct LogWeightUseCase: Sendable {
    private let weightRepository: any WeightRepository

    public init(weightRepository: any WeightRepository) {
        self.weightRepository = weightRepository
    }

    @discardableResult
    public func callAsFunction(
        weightKg: Double,
        recordedAt: Date = Date(),
        withCreatine: Bool? = nil,
        calendar: Calendar = .current
    ) async throws(DomainError) -> WeightEntry {
        let creatine: Bool = if let withCreatine {
            withCreatine
        } else {
            try await weightRepository.latest()?.withCreatine ?? false
        }
        let entry = WeightEntry(
            dayKey: DayKey.make(for: recordedAt, calendar: calendar),
            weightKg: weightKg,
            recordedAt: recordedAt,
            withCreatine: creatine
        )
        try await weightRepository.save(entry)
        return entry
    }
}
