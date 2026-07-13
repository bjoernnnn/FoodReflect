import Domain
import Foundation

final class FakeFoodCatalogRepository: FoodCatalogRepository, @unchecked Sendable {
    var localResults: [Food] = []
    var shouldThrow = false
    private(set) var recordedUsage: [(foodID: UUID, date: Date)] = []
    private(set) var saved: [Food] = []

    func food(barcode: String) async throws(DomainError) -> Food? {
        localResults.first { $0.barcode == barcode }
    }

    func search(localQuery query: String) async throws(DomainError) -> [Food] {
        if shouldThrow {
            throw DomainError.offline
        }
        return localResults.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func save(_ food: Food) async throws(DomainError) {
        saved.append(food)
    }

    func recordUsage(foodID: UUID, at date: Date) async throws(DomainError) {
        recordedUsage.append((foodID, date))
    }
}

final class FakeFoodDataSource: FoodDataSource, @unchecked Sendable {
    var remoteResults: [Food] = []
    var shouldThrow = false

    func fetchProduct(barcode: String) async throws(DomainError) -> Food? {
        remoteResults.first { $0.barcode == barcode }
    }

    func search(query: String) async throws(DomainError) -> [Food] {
        if shouldThrow {
            throw DomainError.offline
        }
        return remoteResults.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

final class FakeDiaryRepository: DiaryRepository, @unchecked Sendable {
    private(set) var saved: [DiaryEntry] = []

    func entries(on dayKey: String) async throws(DomainError) -> [DiaryEntry] {
        saved.filter { $0.dayKey == dayKey }
    }

    func entries(fromDayKey _: String, toDayKey _: String) async throws(DomainError) -> [DiaryEntry] {
        saved
    }

    func save(_ entry: DiaryEntry) async throws(DomainError) {
        saved.append(entry)
    }

    func delete(entryID: UUID) async throws(DomainError) {
        saved.removeAll { $0.id == entryID }
    }
}
