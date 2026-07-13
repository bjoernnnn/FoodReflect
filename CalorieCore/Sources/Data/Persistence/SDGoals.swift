import Foundation
import SwiftData

/// Es existiert zur Laufzeit maximal eine Zeile (der aktuell aktive Zielsatz).
@Model
public final class SDGoals {
    public var id = UUID()
    public var dailyKcal: Int = 0
    public var proteinGrams: Int = 0
    public var carbsGrams: Int = 0
    public var fatGrams: Int = 0
    public var isCustomized: Bool = false

    public init(
        id: UUID = UUID(),
        dailyKcal: Int = 0,
        proteinGrams: Int = 0,
        carbsGrams: Int = 0,
        fatGrams: Int = 0,
        isCustomized: Bool = false
    ) {
        self.id = id
        self.dailyKcal = dailyKcal
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.isCustomized = isCustomized
    }
}
