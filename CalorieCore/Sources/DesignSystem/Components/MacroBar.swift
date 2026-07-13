import SwiftUI

/// Schlanker Fortschrittsbalken für ein Makro (Ist vs. Ziel).
public struct MacroBar: View {
    private let title: String
    private let currentGrams: Double
    private let targetGrams: Double
    private let tint: Color

    public init(title: String, currentGrams: Double, targetGrams: Double, tint: Color) {
        self.title = title
        self.currentGrams = currentGrams
        self.targetGrams = targetGrams
        self.tint = tint
    }

    private var progress: Double {
        guard targetGrams > 0 else { return 0 }
        return min(currentGrams / targetGrams, 1)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
                Spacer()
                Text("\(Int(currentGrams))g / \(Int(targetGrams))g")
                    .font(TypographyToken.caption)
                    .foregroundStyle(ColorToken.secondaryText)
            }
            ProgressView(value: progress)
                .tint(tint)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(Int(currentGrams)) von \(Int(targetGrams)) Gramm")
    }
}

#Preview {
    MacroBar(title: "Protein", currentGrams: 80, targetGrams: 150, tint: .blue)
        .padding()
}
