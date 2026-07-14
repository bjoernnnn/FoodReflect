import Domain
import Foundation
import Testing
@testable import Sync

@Suite("WatchSnapshotMapper")
struct WatchSnapshotMapperTests {
    private let goals = MacroGoals(dailyKcal: 2200, proteinGrams: 165, carbsGrams: 220, fatGrams: 73, isCustomized: false)

    private func dayTotals() -> DayTotals {
        DayTotals(dayKey: "2026-07-14", kcal: 1500, protein: 90, carbs: 150, fat: 50, goals: goals)
    }

    private func item(_ name: String, kcal: Double) -> MealTemplateItem {
        MealTemplateItem(foodName: name, amountGrams: 100, kcal: kcal, protein: 5, carbs: 10, fat: 2)
    }

    @Test("Snapshot übernimmt Tageswerte, Ziel und letztes Gewicht inkl. Kreatin")
    func mapsTotalsAndWeight() {
        let weight = WeightEntry(dayKey: "2026-07-14", weightKg: 81.4, recordedAt: Date(), withCreatine: true)
        let snapshot = WatchSnapshotMapper.snapshot(
            dayTotals: dayTotals(),
            latestWeight: weight,
            quickList: .empty,
            templates: []
        )
        #expect(snapshot.consumedKcal == 1500)
        #expect(snapshot.goalKcal == 2200)
        #expect(snapshot.latestWeightKg == 81.4)
        #expect(snapshot.latestCreatine == true)
        #expect(snapshot.remainingKcal == 700)
    }

    @Test("Ohne Messung ist latestWeightKg nil und Kreatin false")
    func mapsNoWeight() {
        let snapshot = WatchSnapshotMapper.snapshot(
            dayTotals: dayTotals(),
            latestWeight: nil,
            quickList: .empty,
            templates: []
        )
        #expect(snapshot.latestWeightKg == nil)
        #expect(snapshot.latestCreatine == false)
    }

    @Test("Schnellauswahl wird in exakter Reihenfolge geflacht, Ordnerinhalte tragen folderName")
    func flattensQuickListPreservingOrder() {
        let meal = MealTemplate(name: "Porridge", items: [item("Haferflocken", kcal: 350)])
        let topFood = QuickListLeaf.food(id: UUID(), item: item("Apfel", kcal: 52))
        let folderFood = QuickListLeaf.food(id: UUID(), item: item("Nuss", kcal: 90))
        let mealLeaf = QuickListLeaf.meal(id: UUID(), templateID: meal.id)

        let quickList = QuickList(entries: [
            .leaf(mealLeaf),
            .leaf(topFood),
            .folder(id: UUID(), name: "Snacks", items: [folderFood])
        ])

        let snapshot = WatchSnapshotMapper.snapshot(
            dayTotals: dayTotals(),
            latestWeight: nil,
            quickList: quickList,
            templates: [meal]
        )

        #expect(snapshot.quickItems.count == 3)
        // Reihenfolge bleibt: Gericht, Top-Level-Food, dann Ordner-Food.
        #expect(snapshot.quickItems[0].title == "Porridge")
        #expect(snapshot.quickItems[0].isMeal == true)
        #expect(snapshot.quickItems[0].kcal == 350)
        #expect(snapshot.quickItems[0].folderName == nil)
        #expect(snapshot.quickItems[1].title == "Apfel")
        #expect(snapshot.quickItems[1].folderName == nil)
        #expect(snapshot.quickItems[2].title == "Nuss")
        #expect(snapshot.quickItems[2].folderName == "Snacks")
    }

    @Test("Gericht ohne passendes Template fällt auf Platzhalter zurück (kein Crash)")
    func missingTemplateFallsBack() {
        let orphanLeaf = QuickListLeaf.meal(id: UUID(), templateID: UUID())
        let snapshot = WatchSnapshotMapper.snapshot(
            dayTotals: dayTotals(),
            latestWeight: nil,
            quickList: QuickList(entries: [.leaf(orphanLeaf)]),
            templates: []
        )
        #expect(snapshot.quickItems.first?.title == "Gericht")
        #expect(snapshot.quickItems.first?.kcal == 0)
    }

    @Test("Referenz→Leaf: Food behält den Nährwert-Snapshot")
    func referenceToFoodLeaf() {
        let snapshot = FoodSnapshot(foodID: UUID(), foodName: "Reis", amountGrams: 120, kcal: 156, protein: 3, carbs: 34, fat: 0)
        let leaf = WatchSnapshotMapper.leaf(from: .food(item: snapshot))
        guard case let .food(_, mapped) = leaf else {
            Issue.record("Erwartet .food")
            return
        }
        #expect(mapped.foodName == "Reis")
        #expect(mapped.amountGrams == 120)
        #expect(mapped.kcal == 156)
        #expect(mapped.foodID == snapshot.foodID)
    }

    @Test("Referenz→Leaf: Meal behält die templateID")
    func referenceToMealLeaf() {
        let templateID = UUID()
        let leaf = WatchSnapshotMapper.leaf(from: .meal(templateID: templateID))
        guard case let .meal(_, mappedID) = leaf else {
            Issue.record("Erwartet .meal")
            return
        }
        #expect(mappedID == templateID)
    }
}
