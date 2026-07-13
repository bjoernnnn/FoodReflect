import Foundation

/// Typisierte Fehler, die Repositories, Data Sources und UseCases werfen.
/// ViewModels mappen sie auf `ViewState.error` statt auf Alert-Spam.
public enum DomainError: Error, Equatable, Sendable {
    case invalidAmount
    case notFound
    case offline
    case timeout
    case network(String)
    case decoding(String)
}
