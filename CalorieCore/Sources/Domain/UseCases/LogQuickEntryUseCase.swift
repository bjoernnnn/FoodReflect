import Foundation

/// Expandiert ein Schnellauswahl-Blatt in `DiaryEntry`(s): ein Lebensmittel-Blatt ergibt genau
/// einen Eintrag aus seinem Snapshot, ein Gericht-Blatt wird über sein `MealTemplate` expandiert.
/// Speichert **nicht** selbst – Persistenz + Idempotenz (Event-UUID) liegen in der Sync-Schicht (9.3).
public struct LogQuickEntryUseCase: Sendable {
    private let mealTemplateRepository: any MealTemplateRepository
    private let logMealTemplate = LogMealTemplateUseCase()

    public init(mealTemplateRepository: any MealTemplateRepository) {
        self.mealTemplateRepository = mealTemplateRepository
    }

    public func callAsFunction(
        leaf: QuickListLeaf,
        consumedAt: Date = Date(),
        calendar: Calendar = .current
    ) async throws(DomainError) -> [DiaryEntry] {
        switch leaf {
        case let .food(_, item):
            return [DiaryEntry(
                consumedAt: consumedAt,
                dayKey: DayKey.make(for: consumedAt, calendar: calendar),
                foodName: item.foodName,
                amountGrams: item.amountGrams,
                kcal: item.kcal,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                foodID: item.foodID,
                mealType: MealType.make(for: consumedAt, calendar: calendar)
            )]
        case let .meal(_, templateID):
            guard let template = try await mealTemplateRepository.template(id: templateID) else { return [] }
            return logMealTemplate(template: template, consumedAt: consumedAt, calendar: calendar)
        }
    }
}
