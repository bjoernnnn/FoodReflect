import Foundation
import SwiftData

/// Genau eine Schnellauswahl-Zeile pro Nutzer (Singleton). Die geordneten Einträge inkl. Ordner
/// liegen als codiertes `Data`-Blob (`entriesData`) – die verschachtelte Enum-Struktur lässt sich so
/// ohne Kind-Beziehungen persistieren und CloudKit-sicher spiegeln.
@Model
public final class SDQuickList {
    public var id = UUID()
    public var entriesData = Data()

    public init(id: UUID = UUID(), entriesData: Data = Data()) {
        self.id = id
        self.entriesData = entriesData
    }
}
