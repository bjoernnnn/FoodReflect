import Foundation

/// Leitet den Tages-Schlüssel ("2026-07-13") konsequent aus lokaler Kalender-Mitternacht ab.
/// Zentral an einer Stelle, damit Tageswechsel/Zeitzonenlogik in Tests fixierbar bleibt.
public enum DayKey {
    public static func make(for date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return ""
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
}
