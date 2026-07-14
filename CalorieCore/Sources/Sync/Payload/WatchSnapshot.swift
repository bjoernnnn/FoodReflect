import Foundation

/// Autoritativer Zustand, den das iPhone der Watch per `updateApplicationContext` schickt.
/// Bewusst **display-fertig denormalisiert**: die Watch braucht kein SwiftData/Data-Layer,
/// nur diese Primitiven zum Rendern von Komplikationen und Screens.
public struct WatchSnapshot: Codable, Equatable, Sendable {
    /// Kalorien-Ring: heute gegessen + Tagesziel (Rest wird auf der Watch berechnet).
    public var consumedKcal: Double
    public var goalKcal: Int
    public var proteinGrams: Double
    public var carbsGrams: Double
    public var fatGrams: Double

    /// Gewichts-Komplikation/-Screen: letzter Wert + Kreatin-Stand (nil ⇒ noch keine Messung).
    public var latestWeightKg: Double?
    public var latestCreatine: Bool

    /// Schnellauswahl in exakt der iPhone-Reihenfolge, flach + display-fertig.
    public var quickItems: [WatchQuickItem]

    /// Kalorien-Ring-Mitte: „Übrig" (Default) oder „Gegessen".
    public var calorieDisplayMode: CalorieDisplayMode

    public init(
        consumedKcal: Double,
        goalKcal: Int,
        proteinGrams: Double,
        carbsGrams: Double,
        fatGrams: Double,
        latestWeightKg: Double?,
        latestCreatine: Bool,
        quickItems: [WatchQuickItem],
        calorieDisplayMode: CalorieDisplayMode
    ) {
        self.consumedKcal = consumedKcal
        self.goalKcal = goalKcal
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.latestWeightKg = latestWeightKg
        self.latestCreatine = latestCreatine
        self.quickItems = quickItems
        self.calorieDisplayMode = calorieDisplayMode
    }

    public var remainingKcal: Double {
        Double(goalKcal) - consumedKcal
    }

    /// Leerer Startzustand, bis der erste echte Context vom iPhone eintrifft.
    public static let empty = WatchSnapshot(
        consumedKcal: 0,
        goalKcal: 2000,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        latestWeightKg: nil,
        latestCreatine: false,
        quickItems: [],
        calorieDisplayMode: .remaining
    )

    /// Repräsentative Beispieldaten für die Komplikations-Galerie / SwiftUI-Previews.
    public static let sample = WatchSnapshot(
        consumedKcal: 1450,
        goalKcal: 2200,
        proteinGrams: 95,
        carbsGrams: 160,
        fatGrams: 48,
        latestWeightKg: 81.4,
        latestCreatine: true,
        quickItems: [],
        calorieDisplayMode: .remaining
    )
}

/// Ein flacher Eintrag der Schnellauswahl für die Watch – Ordner werden beim Mapping
/// als Kopfzeilen (`folderName`) mitgegeben, damit die Reihenfolge 1:1 erhalten bleibt.
public struct WatchQuickItem: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public var title: String
    public var kcal: Double
    public var isMeal: Bool
    /// Referenz auf das iPhone-Objekt, das beim Loggen expandiert wird.
    public var reference: WatchQuickReference
    /// nil ⇒ oberste Ebene; sonst Name des enthaltenden Ordners.
    public var folderName: String?

    public init(
        id: UUID,
        title: String,
        kcal: Double,
        isMeal: Bool,
        reference: WatchQuickReference,
        folderName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.kcal = kcal
        self.isMeal = isMeal
        self.reference = reference
        self.folderName = folderName
    }
}

/// Womit ein Schnellauswahl-Eintrag beim Loggen aufgelöst wird.
public enum WatchQuickReference: Codable, Equatable, Sendable {
    case meal(templateID: UUID)
    case food(item: FoodSnapshot)
}

/// Denormalisierter Nährwert-Snapshot eines Einzel-Lebensmittels (stabil, offline-fest).
public struct FoodSnapshot: Codable, Equatable, Sendable {
    public var foodID: UUID?
    public var foodName: String
    public var amountGrams: Double
    public var kcal: Double
    public var protein: Double
    public var carbs: Double
    public var fat: Double

    public init(
        foodID: UUID?,
        foodName: String,
        amountGrams: Double,
        kcal: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        self.foodID = foodID
        self.foodName = foodName
        self.amountGrams = amountGrams
        self.kcal = kcal
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

public enum CalorieDisplayMode: String, Codable, Equatable, Sendable {
    case remaining
    case consumed
}
