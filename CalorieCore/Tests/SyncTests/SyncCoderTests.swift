import Foundation
import Testing
@testable import Sync

@Suite("SyncCoder")
struct SyncCoderTests {
    private var sampleSnapshot: WatchSnapshot {
        WatchSnapshot(
            consumedKcal: 1234,
            goalKcal: 2200,
            proteinGrams: 88,
            carbsGrams: 140,
            fatGrams: 55,
            latestWeightKg: 81.4,
            latestCreatine: true,
            quickItems: [
                WatchQuickItem(id: UUID(), title: "Porridge", kcal: 350, isMeal: true, reference: .meal(templateID: UUID()))
            ],
            calorieDisplayMode: .remaining
        )
    }

    private var sampleEvent: WatchEvent {
        WatchEvent(
            id: UUID(),
            kind: .logWeight(weightKg: 81.4, creatine: true),
            occurredAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    @Test("Snapshot überlebt Encode→Decode unverändert")
    func snapshotRoundTrip() throws {
        let original = sampleSnapshot
        let dict = try SyncCoder.encode(original)
        let decoded = try SyncCoder.decodeSnapshot(from: dict)
        #expect(decoded == original)
    }

    @Test("Event überlebt Encode→Decode unverändert")
    func eventRoundTrip() throws {
        let original = sampleEvent
        let dict = try SyncCoder.encode(original)
        let decoded = try SyncCoder.decodeEvent(from: dict)
        #expect(decoded == original)
    }

    @Test("Envelope trägt die aktuelle schemaVersion und eine Data-Payload")
    func envelopeShape() throws {
        let dict = try SyncCoder.encode(sampleSnapshot)
        #expect(dict[SyncCoder.versionKey] as? Int == SyncCoder.schemaVersion)
        #expect(dict[SyncCoder.payloadKey] is Data)
    }

    @Test("Unbekannte (neuere) schemaVersion wird abgelehnt statt zu crashen")
    func unknownVersionRejected() throws {
        var dict = try SyncCoder.encode(sampleSnapshot)
        dict[SyncCoder.versionKey] = 999
        #expect(throws: SyncCoder.CoderError.unsupportedVersion(999)) {
            try SyncCoder.decodeSnapshot(from: dict)
        }
    }

    @Test("Fehlende Version wird abgelehnt")
    func missingVersionRejected() throws {
        var dict = try SyncCoder.encode(sampleSnapshot)
        dict.removeValue(forKey: SyncCoder.versionKey)
        #expect(throws: SyncCoder.CoderError.unsupportedVersion(nil)) {
            try SyncCoder.decodeSnapshot(from: dict)
        }
    }

    @Test("Kaputte Payload ergibt malformedPayload statt Crash")
    func malformedPayload() {
        let dict: [String: Any] = [SyncCoder.versionKey: SyncCoder.schemaVersion, SyncCoder.payloadKey: Data([0x00, 0x01])]
        #expect(throws: SyncCoder.CoderError.malformedPayload) {
            try SyncCoder.decodeSnapshot(from: dict)
        }
    }
}
