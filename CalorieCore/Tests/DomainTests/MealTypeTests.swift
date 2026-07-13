import Foundation
import Testing
@testable import Domain

@Suite("MealType")
struct MealTypeTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(hour: Int) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 7
        components.day = 13
        components.hour = hour
        return utcCalendar.date(from: components)!
    }

    @Test("Uhrzeit-Ableitung: <11 Frühstück, <15 Mittag, <21 Abend, sonst Snack")
    func derivesFromHour() {
        #expect(MealType.make(for: date(hour: 8), calendar: utcCalendar) == .breakfast)
        #expect(MealType.make(for: date(hour: 10), calendar: utcCalendar) == .breakfast)
        #expect(MealType.make(for: date(hour: 11), calendar: utcCalendar) == .lunch)
        #expect(MealType.make(for: date(hour: 14), calendar: utcCalendar) == .lunch)
        #expect(MealType.make(for: date(hour: 15), calendar: utcCalendar) == .dinner)
        #expect(MealType.make(for: date(hour: 20), calendar: utcCalendar) == .dinner)
        #expect(MealType.make(for: date(hour: 21), calendar: utcCalendar) == .snack)
        #expect(MealType.make(for: date(hour: 23), calendar: utcCalendar) == .snack)
    }

    @Test("RawValue ist stabil (Persistenz-/Sync-Kontrakt)")
    func rawValuesAreStable() {
        #expect(MealType.breakfast.rawValue == "breakfast")
        #expect(MealType.lunch.rawValue == "lunch")
        #expect(MealType.dinner.rawValue == "dinner")
        #expect(MealType.snack.rawValue == "snack")
        #expect(MealType(rawValue: "unbekannt") == nil)
    }

    @Test("sortOrder ordnet Frühstück → Snack unabhängig von der Uhrzeit")
    func sortOrderIsChronologicalByMeal() {
        let shuffled: [MealType] = [.snack, .breakfast, .dinner, .lunch]
        #expect(shuffled.sorted { $0.sortOrder < $1.sortOrder } == [.breakfast, .lunch, .dinner, .snack])
    }
}
