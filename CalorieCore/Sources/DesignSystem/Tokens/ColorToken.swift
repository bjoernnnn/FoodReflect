import SwiftUI
import UIKit

/// systemBackground-basiert, eine Akzentfarbe. Kein SPM-Resource-Bundling nötig,
/// da als Werte statt Asset-Catalog-Referenz definiert (Package-Targets haben
/// keinen eigenen Asset-Catalog-Zugriff über die App-Grenze hinweg).
public enum ColorToken {
    /// Türkis, angelehnt an das App-Icon (Schüssel/Blatt).
    public static let accent = Color(red: 0.086, green: 0.635, blue: 0.573)
    public static let warning = Color(red: 0.949, green: 0.302, blue: 0.263)

    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
}
