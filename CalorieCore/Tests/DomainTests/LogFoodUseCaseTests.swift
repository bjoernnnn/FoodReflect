import Foundation
import Testing
@testable import Domain

@Suite("LogFoodUseCase")
struct LogFoodUseCaseTests {
    let sut = LogFoodUseCase()

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private var nutella: Food {
        Food(
            name: "Nutella",
            kcalPer100g: 539,
            proteinPer100g: 6.3,
            carbsPer100g: 57.5,
            fatPer100g: 30.9,
            source: .openFoodFacts(code: "3017620422003")
        )
    }

    @Test("100 g entspricht exakt den per-100g-Werten")
    func fullPortion() throws {
        let food = nutella
        let date = Date(timeIntervalSince1970: 1_752_364_800) // 2025-07-13 00:00 UTC
        let entry = try sut(food: food, amountGrams: 100, consumedAt: date, calendar: utcCalendar)
        #expect(entry.kcal == 539)
        #expect(entry.protein == 6.3)
        #expect(entry.carbs == 57.5)
        #expect(entry.fat == 30.9)
        #expect(entry.dayKey == "2025-07-13")
        #expect(entry.foodID == food.id)
        #expect(entry.foodName == "Nutella")
    }

    @Test("0 g ist ein gültiger Randfall und liefert einen Nullsnapshot")
    func zeroGrams() throws {
        let entry = try sut(food: nutella, amountGrams: 0, calendar: utcCalendar)
        #expect(entry.kcal == 0)
        #expect(entry.protein == 0)
        #expect(entry.carbs == 0)
        #expect(entry.fat == 0)
    }

    @Test("Negative Menge wirft DomainError.invalidAmount")
    func negativeAmountThrows() {
        #expect(throws: DomainError.invalidAmount) {
            try sut(food: nutella, amountGrams: -1, calendar: utcCalendar)
        }
    }

    @Test("Krumme Mengen runden Makros auf eine Nachkommastelle")
    func fractionalAmountRounds() throws {
        let entry = try sut(food: nutella, amountGrams: 33, calendar: utcCalendar)
        // 6.3 * 0.33 = 2.079 -> 2.1
        #expect(entry.protein == 2.1)
    }

    @Test("Snapshot ist unabhängig von späteren Food-Änderungen (kein Live-Lookup)")
    func snapshotIsIndependentOfFoodMutation() throws {
        var food = nutella
        let entry = try sut(food: food, amountGrams: 100, calendar: utcCalendar)
        food.kcalPer100g = 999 // simuliert nachträgliches Edit des Katalog-Eintrags
        #expect(entry.kcal == 539) // Snapshot bleibt unverändert
    }

    @Test("Ohne expliziten mealType wird er aus consumedAt abgeleitet")
    func mealTypeDerivedFromTime() throws {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 13; components.hour = 8
        let morning = try #require(utcCalendar.date(from: components))
        let entry = try sut(food: nutella, amountGrams: 100, consumedAt: morning, calendar: utcCalendar)
        #expect(entry.mealType == .breakfast)
    }

    @Test("Expliziter mealType hat Vorrang vor der Uhrzeit-Ableitung")
    func explicitMealTypeWins() throws {
        var components = DateComponents()
        components.year = 2026; components.month = 7; components.day = 13; components.hour = 8
        let morning = try #require(utcCalendar.date(from: components))
        let entry = try sut(food: nutella, amountGrams: 100, consumedAt: morning, mealType: .dinner, calendar: utcCalendar)
        #expect(entry.mealType == .dinner)
    }
}
