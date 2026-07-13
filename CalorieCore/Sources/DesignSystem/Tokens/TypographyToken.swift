import SwiftUI

/// SF-Pro-Typo mit klarer Größenhierarchie. Rest-kcal ist die eine Zahl, die zählt (≥ 48 pt bold rounded).
public enum TypographyToken {
    public static let remainingKcal = Font.system(size: 56, weight: .bold, design: .rounded)
    public static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
}
