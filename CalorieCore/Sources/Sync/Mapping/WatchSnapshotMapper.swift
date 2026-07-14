import Domain
import Foundation

/// Übersetzt zwischen dem iPhone-Domänenmodell und den display-fertigen Watch-DTOs.
public enum WatchSnapshotMapper {
    /// Baut den autoritativen Snapshot fürs iPhone→Watch-Push. Die Schnellauswahl wird in exakt
    /// der iPhone-Reihenfolge geflacht: Top-Level-Blätter bleiben an ihrer Position, Ordnerinhalte
    /// erscheinen gruppiert unter dem Ordner (mit `folderName`).
    public static func snapshot(
        dayTotals: DayTotals,
        latestWeight: WeightEntry?,
        quickList: QuickList,
        templates: [MealTemplate],
        calorieDisplayMode: CalorieDisplayMode = .remaining
    ) -> WatchSnapshot {
        let templatesByID = Dictionary(templates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var items: [WatchQuickItem] = []
        for entry in quickList.entries {
            switch entry {
            case let .leaf(leaf):
                items.append(quickItem(for: leaf, templatesByID: templatesByID, folderName: nil))
            case let .folder(_, name, leaves):
                for leaf in leaves {
                    items.append(quickItem(for: leaf, templatesByID: templatesByID, folderName: name))
                }
            }
        }
        return WatchSnapshot(
            consumedKcal: dayTotals.kcal,
            goalKcal: dayTotals.goals.dailyKcal,
            proteinGrams: dayTotals.protein,
            carbsGrams: dayTotals.carbs,
            fatGrams: dayTotals.fat,
            latestWeightKg: latestWeight?.weightKg,
            latestCreatine: latestWeight?.withCreatine ?? false,
            quickItems: items,
            calorieDisplayMode: calorieDisplayMode
        )
    }

    private static func quickItem(
        for leaf: QuickListLeaf,
        templatesByID: [UUID: MealTemplate],
        folderName: String?
    ) -> WatchQuickItem {
        switch leaf {
        case let .meal(id, templateID):
            let template = templatesByID[templateID]
            return WatchQuickItem(
                id: id,
                title: template?.name ?? "Gericht",
                kcal: template?.totalKcal ?? 0,
                isMeal: true,
                reference: .meal(templateID: templateID),
                folderName: folderName
            )
        case let .food(id, item):
            return WatchQuickItem(
                id: id,
                title: item.foodName,
                kcal: item.kcal,
                isMeal: false,
                reference: .food(item: foodSnapshot(from: item)),
                folderName: folderName
            )
        }
    }

    // MARK: - Referenz → Domäne (beim Loggen auf dem iPhone)

    /// Löst eine Watch-Referenz in ein `QuickListLeaf` auf, das `LogQuickEntryUseCase` versteht.
    public static func leaf(from reference: WatchQuickReference) -> QuickListLeaf {
        switch reference {
        case let .meal(templateID):
            .meal(id: UUID(), templateID: templateID)
        case let .food(item):
            .food(id: UUID(), item: mealTemplateItem(from: item))
        }
    }

    // MARK: - FoodSnapshot ↔ MealTemplateItem

    static func foodSnapshot(from item: MealTemplateItem) -> FoodSnapshot {
        FoodSnapshot(
            foodID: item.foodID,
            foodName: item.foodName,
            amountGrams: item.amountGrams,
            kcal: item.kcal,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat
        )
    }

    static func mealTemplateItem(from snapshot: FoodSnapshot) -> MealTemplateItem {
        MealTemplateItem(
            foodID: snapshot.foodID,
            foodName: snapshot.foodName,
            amountGrams: snapshot.amountGrams,
            kcal: snapshot.kcal,
            protein: snapshot.protein,
            carbs: snapshot.carbs,
            fat: snapshot.fat
        )
    }
}
