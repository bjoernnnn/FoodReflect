import Domain
import Foundation

enum WeightEntryMapper {
    static func toDomain(_ model: SDWeightEntry) -> WeightEntry {
        WeightEntry(
            id: model.id,
            dayKey: model.dayKey,
            weightKg: model.weightKg,
            recordedAt: model.recordedAt,
            withCreatine: model.withCreatine
        )
    }

    static func toModel(_ entry: WeightEntry) -> SDWeightEntry {
        SDWeightEntry(
            id: entry.id,
            dayKey: entry.dayKey,
            weightKg: entry.weightKg,
            recordedAt: entry.recordedAt,
            withCreatine: entry.withCreatine
        )
    }
}
