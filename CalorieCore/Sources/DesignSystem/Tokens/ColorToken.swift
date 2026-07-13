import SwiftUI
import UIKit

/// systemBackground-basiert, eine Akzentfarbe. Kein SPM-Resource-Bundling nötig,
/// da als Werte statt Asset-Catalog-Referenz definiert (Package-Targets haben
/// keinen eigenen Asset-Catalog-Zugriff über die App-Grenze hinweg).
public enum ColorToken {
    /// Türkis, angelehnt an das App-Icon (Schüssel/Blatt).
    public static let accent = Color(red: 0.086, green: 0.635, blue: 0.573)
    public static let warning = Color(red: 0.949, green: 0.302, blue: 0.263)
    /// Für semantische Delta-Anzeigen (z. B. Gewichtsabnahme), unabhängig vom Makro-Grün.
    public static let positive = Color(red: 0.20, green: 0.70, blue: 0.35)

    /// Makro-Farben – zentrale Single Source of Truth, überall (Dashboard-Ring,
    /// MacroBar, Widget) statt inline `.blue`/`.orange`/`.pink` verwendet.
    public static let proteinColor = Color(red: 0.20, green: 0.55, blue: 0.95)
    public static let carbsColor = Color(red: 0.98, green: 0.62, blue: 0.09)
    public static let fatColor = Color(red: 0.93, green: 0.31, blue: 0.55)

    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
}
