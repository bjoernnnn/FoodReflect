import Foundation
import Testing
@testable import Sync

@Suite("EventDeduplicator")
struct EventDeduplicatorTests {
    private func event(id: UUID = UUID()) -> WatchEvent {
        WatchEvent(id: id, kind: .logWeight(weightKg: 80, creatine: false), occurredAt: Date())
    }

    @Test("Neues Event wird genau einmal verarbeitet")
    func firstDeliveryProcessed() {
        let sut = EventDeduplicator(store: InMemoryProcessedEventStore())
        #expect(sut.shouldProcess(event()))
    }

    @Test("Doppelte Zustellung derselben ID wird verworfen")
    func duplicateRejected() {
        let sut = EventDeduplicator(store: InMemoryProcessedEventStore())
        let duplicate = event()
        #expect(sut.shouldProcess(duplicate))
        #expect(sut.shouldProcess(duplicate) == false)
        #expect(sut.shouldProcess(duplicate) == false)
    }

    @Test("Unterschiedliche Events werden unabhängig verarbeitet")
    func differentEventsIndependent() {
        let sut = EventDeduplicator(store: InMemoryProcessedEventStore())
        #expect(sut.shouldProcess(event()))
        #expect(sut.shouldProcess(event()))
    }

    @Test("Bereits bekannte IDs aus dem Store werden sofort verworfen (persistenter Cache)")
    func preseededStoreRejects() {
        let known = UUID()
        let sut = EventDeduplicator(store: InMemoryProcessedEventStore(ids: [known]))
        #expect(sut.shouldProcess(event(id: known)) == false)
    }
}
