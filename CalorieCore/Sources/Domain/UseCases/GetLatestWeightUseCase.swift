import Foundation

/// Liefert die zeitlich jüngste Gewichtsmessung (für Komplikation, Startwert der Watch-Eingabe
/// und den Kreatin-Default). `nil`, solange noch nichts erfasst wurde.
public struct GetLatestWeightUseCase: Sendable {
    private let weightRepository: any WeightRepository

    public init(weightRepository: any WeightRepository) {
        self.weightRepository = weightRepository
    }

    public func callAsFunction() async throws(DomainError) -> WeightEntry? {
        try await weightRepository.latest()
    }
}
