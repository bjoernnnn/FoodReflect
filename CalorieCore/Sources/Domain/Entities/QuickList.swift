import Foundation

/// Ein loggbares Blatt der Schnellauswahl: entweder ein Gericht (Referenz auf `MealTemplate`)
/// oder ein einzelnes Lebensmittel (mit fixiertem Nährwert-Snapshot, offline loggbar).
public enum QuickListLeaf: Identifiable, Hashable, Sendable, Codable {
    case meal(id: UUID, templateID: UUID)
    case food(id: UUID, item: MealTemplateItem)

    public var id: UUID {
        switch self {
        case let .meal(id, _): id
        case let .food(id, _): id
        }
    }
}

/// Ein Eintrag der Schnellauswahl auf oberster Ebene: ein Blatt oder ein Ordner
/// (max. eine Ebene tief, enthält nur Blätter – siehe Spezifikation Abschnitt 2).
public enum QuickListEntry: Identifiable, Hashable, Sendable, Codable {
    case leaf(QuickListLeaf)
    case folder(id: UUID, name: String, items: [QuickListLeaf])

    public var id: UUID {
        switch self {
        case let .leaf(leaf): leaf.id
        case let .folder(id, _, _): id
        }
    }
}

/// Genau eine Schnellauswahl pro Nutzer – geordnete Liste, auf dem iPhone konfiguriert,
/// zur Watch gespiegelt.
public struct QuickList: Hashable, Sendable {
    public var entries: [QuickListEntry]

    public init(entries: [QuickListEntry] = []) {
        self.entries = entries
    }

    public static let empty = QuickList()

    /// Alle Blätter in Anzeigereihenfolge, flach (Ordner werden aufgelöst) – praktisch für die
    /// Watch-Liste und Tests.
    public var flattenedLeaves: [QuickListLeaf] {
        entries.flatMap { entry -> [QuickListLeaf] in
            switch entry {
            case let .leaf(leaf): [leaf]
            case let .folder(_, _, items): items
            }
        }
    }
}
