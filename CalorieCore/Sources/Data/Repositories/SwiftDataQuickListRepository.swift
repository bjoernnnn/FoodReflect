import Domain
import Foundation
import SwiftData

@ModelActor
public actor SwiftDataQuickListRepository: QuickListRepository {
    public func load() async throws(DomainError) -> QuickList {
        do {
            guard let row = try modelContext.fetch(FetchDescriptor<SDQuickList>()).first else {
                return .empty
            }
            let entries = (try? JSONDecoder().decode([QuickListEntry].self, from: row.entriesData)) ?? []
            return QuickList(entries: entries)
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }

    public func save(_ quickList: QuickList) async throws(DomainError) {
        let data = (try? JSONEncoder().encode(quickList.entries)) ?? Data()
        do {
            if let existing = try modelContext.fetch(FetchDescriptor<SDQuickList>()).first {
                existing.entriesData = data
            } else {
                modelContext.insert(SDQuickList(entriesData: data))
            }
            try modelContext.save()
        } catch {
            throw DomainError.decoding("\(error)")
        }
    }
}
