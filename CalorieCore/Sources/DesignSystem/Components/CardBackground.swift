import SwiftUI

public struct CardBackground: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(ColorToken.secondaryBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

public extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
