import Foundation
import SwiftData

/// CloudKit-kompatibel: keine `.unique`-Attribute, alle Properties mit Defaults, kein `@Relationship`.
/// Die Items werden als codiertes `Data`-Blob gehalten (`itemsData`) – das hält die Vorlage atomar
/// und synct sauber, ohne Kind-Beziehungen.
@Model
public final class SDMealTemplate {
    public var id = UUID()
    public var name: String = ""
    /// Roh-String des optionalen `MealType`; "" bedeutet „kein Vorschlag".
    public var mealTypeRaw: String = ""
    public var itemsData = Data()

    public init(id: UUID = UUID(), name: String = "", mealTypeRaw: String = "", itemsData: Data = Data()) {
        self.id = id
        self.name = name
        self.mealTypeRaw = mealTypeRaw
        self.itemsData = itemsData
    }
}
