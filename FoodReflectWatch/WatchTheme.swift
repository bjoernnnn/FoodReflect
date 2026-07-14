import SwiftUI

/// Lokale Design-Konstanten der Watch-App. `DesignSystem` importiert UIKit und ist damit nicht
/// watchOS-fähig – die Akzent-/Makrofarben sind hier 1:1 aus `ColorToken` gespiegelt.
enum WatchTheme {
    static let accent = Color(red: 0.086, green: 0.635, blue: 0.573)
    static let protein = Color(red: 0.20, green: 0.55, blue: 0.95)
    static let carbs = Color(red: 0.98, green: 0.62, blue: 0.09)
    static let fat = Color(red: 0.93, green: 0.31, blue: 0.55)

    /// Watch-interne App Group (App ↔ Widget-Extension), Quelle des gecachten Snapshots.
    static let appGroupID = "group.com.bjoernnnn.foodreflect.watch"
}
