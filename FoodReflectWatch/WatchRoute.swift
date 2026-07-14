import Foundation

/// Ziele der Deep Links aus den Komplikationen. URL-Schema: `foodreflect://watch/<route>`.
/// Jede Komplikation öffnet direkt „ihren" Screen (Phase 9.1: nur Routing, Screens sind Platzhalter).
enum WatchRoute: String, Hashable, CaseIterable {
    case weight
    case quicklog
    case dashboard

    /// Parst z. B. `foodreflect://watch/weight` → `.weight`. Unbekannte/fremde URLs ⇒ nil.
    init?(url: URL) {
        guard url.scheme == "foodreflect", url.host == "watch" else { return nil }
        let path = url.pathComponents.first { $0 != "/" } ?? ""
        guard let route = WatchRoute(rawValue: path) else { return nil }
        self = route
    }

    var deepLink: URL {
        // Force-unwrap ist sicher: statischer, wohlgeformter String.
        // swiftlint:disable:next force_unwrapping
        URL(string: "foodreflect://watch/\(rawValue)")!
    }
}
