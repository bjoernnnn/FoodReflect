import Foundation
import SwiftData

/// CloudKit-kompatibel: keine `@Attribute(.unique)`, alle Properties mit Defaults.
@Model
public final class SDWeightEntry {
    public var id = UUID()
    public var dayKey: String = ""
    public var weightKg: Double = 0
    public var recordedAt = Date()

    public init(
        id: UUID = UUID(),
        dayKey: String = "",
        weightKg: Double = 0,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.dayKey = dayKey
        self.weightKg = weightKg
        self.recordedAt = recordedAt
    }
}
