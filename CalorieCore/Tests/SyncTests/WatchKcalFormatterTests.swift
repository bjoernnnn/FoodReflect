import Testing
@testable import Sync

@Suite("WatchKcalFormatter")
struct WatchKcalFormatterTests {
    @Test("Werte unter 1000 werden exakt und ohne Suffix gezeigt")
    func exactBelowThousand() {
        #expect(WatchKcalFormatter.compact(0) == "0")
        #expect(WatchKcalFormatter.compact(120) == "120")
        #expect(WatchKcalFormatter.compact(850) == "850")
        #expect(WatchKcalFormatter.compact(999) == "999")
    }

    @Test("Ab 1000 gerundet mit K-Suffix und deutschem Komma")
    func compactThousands() {
        #expect(WatchKcalFormatter.compact(1000) == "1,0K")
        #expect(WatchKcalFormatter.compact(1100) == "1,1K")
        #expect(WatchKcalFormatter.compact(2200) == "2,2K")
    }

    @Test("Negative Restkalorien bekommen ein echtes Minuszeichen")
    func negativeValues() {
        #expect(WatchKcalFormatter.compact(-120) == "\u{2212}120")
        #expect(WatchKcalFormatter.compact(-1500) == "\u{2212}1,5K")
    }

    @Test("Rundet auf ganze Kalorien vor der Formatierung")
    func roundsToWholeKcal() {
        #expect(WatchKcalFormatter.compact(849.6) == "850")
        #expect(WatchKcalFormatter.compact(120.4) == "120")
    }
}
