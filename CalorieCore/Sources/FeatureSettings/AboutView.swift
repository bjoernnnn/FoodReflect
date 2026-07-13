import DesignSystem
import SwiftUI

/// Statische Info-Seite: Version, Datenquelle (Open-Food-Facts-Attribution), Datenschutz.
struct AboutView: View {
    private var version: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        return "\(shortVersion) (\(build))"
    }

    var body: some View {
        List {
            Section("Version") {
                LabeledContent("FoodReflect", value: version)
            }
            Section("Datenquelle") {
                Text(
                    "Lebensmitteldaten stammen von Open Food Facts und stehen unter der " +
                        "Open Database License (ODbL) zur Verfügung."
                )
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
            }
            Section("Datenschutz") {
                Text(
                    "Alle Daten (Tagebuch, Ziele, Gewicht) werden ausschließlich lokal auf diesem Gerät " +
                        "gespeichert. Es gibt keine Cloud-Synchronisation zu FoodReflect-Servern und kein Tracking."
                )
                .font(TypographyToken.caption)
                .foregroundStyle(ColorToken.secondaryText)
            }
        }
        .navigationTitle("Über FoodReflect")
        .navigationBarTitleDisplayMode(.inline)
    }
}
