import Foundation

/// Persistenz der einen Schnellauswahl-Liste. `load` liefert bei Erstnutzung `.empty`.
public protocol QuickListRepository: Sendable {
    func load() async throws(DomainError) -> QuickList
    func save(_ quickList: QuickList) async throws(DomainError)
}
