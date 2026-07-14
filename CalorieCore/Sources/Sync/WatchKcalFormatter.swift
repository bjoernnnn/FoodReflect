import Foundation

/// Formatiert Kalorienwerte für die enge Watch-Anzeige (Komplikation + Ring-Mitte),
/// deutsche Lokalisierung mit Dezimal-Komma und echtem Minuszeichen.
///
/// Regeln (Spezifikation Abschnitt 6):
/// - Betrag < 1000 → exakt („850", „0")
/// - Betrag ≥ 1000 → gerundet mit Suffix und einer Nachkommastelle („1,1K", „2,2K")
/// - negative Restkalorien → führendes „−" („−120")
public enum WatchKcalFormatter {
    private static let minusSign = "\u{2212}" // U+2212, kein ASCII-Bindestrich

    public static func compact(_ value: Double) -> String {
        let rounded = value.rounded()
        let magnitude = abs(rounded)
        let core: String
        if magnitude < 1000 {
            core = String(Int(magnitude))
        } else {
            let thousands = magnitude / 1000
            let formatted = String(format: "%.1f", thousands).replacingOccurrences(of: ".", with: ",")
            core = formatted + "K"
        }
        return rounded < 0 ? minusSign + core : core
    }
}
