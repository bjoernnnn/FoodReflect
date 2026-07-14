import Foundation

/// Lädt die konfigurierte Schnellauswahl (für iPhone-Bearbeitung und Watch-Spiegelung).
public struct GetQuickListUseCase: Sendable {
    private let quickListRepository: any QuickListRepository

    public init(quickListRepository: any QuickListRepository) {
        self.quickListRepository = quickListRepository
    }

    public func callAsFunction() async throws(DomainError) -> QuickList {
        try await quickListRepository.load()
    }
}
