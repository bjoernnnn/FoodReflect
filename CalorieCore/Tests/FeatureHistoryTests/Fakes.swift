import Domain
import Foundation

final class FakeDiaryRepository: DiaryRepository, @unchecked Sendable {
    private(set) var storage: [DiaryEntry]
    var shouldThrow = false

    init(entries: [DiaryEntry] = []) {
        storage = entries
    }

    func entries(on dayKey: String) async throws(DomainError) -> [DiaryEntry] {
        if shouldThrow {
            throw DomainError.notFound
        }
        return storage.filter { $0.dayKey == dayKey }
    }

    func entries(fromDayKey: String, toDayKey: String) async throws(DomainError) -> [DiaryEntry] {
        if shouldThrow {
            throw DomainError.notFound
        }
        return storage.filter { $0.dayKey >= fromDayKey && $0.dayKey <= toDayKey }
    }

    func save(_ entry: DiaryEntry) async throws(DomainError) {
        storage.removeAll { $0.id == entry.id }
        storage.append(entry)
    }

    func delete(entryID: UUID) async throws(DomainError) {
        storage.removeAll { $0.id == entryID }
    }
}

final class FakeGoalsRepository: GoalsRepository, @unchecked Sendable {
    var goals: MacroGoals?

    init(goals: MacroGoals? = nil) {
        self.goals = goals
    }

    func currentGoals() async throws(DomainError) -> MacroGoals? {
        goals
    }

    func save(_ goals: MacroGoals) async throws(DomainError) {
        self.goals = goals
    }
}
