import Foundation
import Testing
@testable import Domain

@Suite("MealTemplate UseCases")
struct MealTemplateUseCaseTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private var haferflocken: Food {
        Food(name: "Haferflocken", kcalPer100g: 370, proteinPer100g: 13, carbsPer100g: 60, fatPer100g: 7, source: .manual)
    }

    private func template(mealType: MealType? = nil) -> MealTemplate {
        MealTemplate(
            name: "Standard-Frühstück",
            mealType: mealType,
            items: [
                MealTemplateItem(foodName: "Haferflocken", amountGrams: 50, kcal: 185, protein: 6.5, carbs: 30, fat: 3.5),
                MealTemplateItem(foodName: "Banane", amountGrams: 120, kcal: 107, protein: 1.3, carbs: 27, fat: 0.4)
            ]
        )
    }

    @Test("BuildMealTemplateItem übernimmt die per-100g-Rechnung von LogFoodUseCase")
    func buildItemMatchesLogFoodMath() throws {
        let sut = BuildMealTemplateItemUseCase()
        let food = haferflocken
        let item = try sut(food: food, amountGrams: 50)
        #expect(item.foodID == food.id)
        #expect(item.foodName == "Haferflocken")
        #expect(item.amountGrams == 50)
        #expect(item.kcal == 185) // 370 * 0.5
        #expect(item.protein == 6.5)
    }

    @Test("Template-Totals summieren die Items")
    func totalsSumItems() {
        let sut = template()
        #expect(sut.totalKcal == 292)
        #expect(abs(sut.totalProtein - 7.8) < 0.0001)
    }

    @Test("LogMealTemplate expandiert in einen Eintrag pro Item mit gemeinsamem Tag/Meal")
    func expandsToOneEntryPerItem() throws {
        let sut = LogMealTemplateUseCase()
        var comps = DateComponents(); comps.year = 2026; comps.month = 7; comps.day = 13; comps.hour = 8
        let morning = try #require(utcCalendar.date(from: comps))
        let entries = sut(template: template(), consumedAt: morning, calendar: utcCalendar)
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.dayKey == "2026-07-13" })
        #expect(entries.allSatisfy { $0.mealType == .breakfast }) // aus Uhrzeit abgeleitet
        #expect(entries.map(\.foodName) == ["Haferflocken", "Banane"])
    }

    @Test("Template-mealType hat Vorrang vor der Uhrzeit, expliziter Parameter schlägt beides")
    func mealTypePrecedence() throws {
        let sut = LogMealTemplateUseCase()
        var comps = DateComponents(); comps.year = 2026; comps.month = 7; comps.day = 13; comps.hour = 8
        let morning = try #require(utcCalendar.date(from: comps))

        let fromTemplate = sut(template: template(mealType: .dinner), consumedAt: morning, calendar: utcCalendar)
        #expect(fromTemplate.allSatisfy { $0.mealType == .dinner })

        let explicit = sut(template: template(mealType: .dinner), consumedAt: morning, mealType: .lunch, calendar: utcCalendar)
        #expect(explicit.allSatisfy { $0.mealType == .lunch })
    }
}
