import SwiftUI

public struct CardBackground: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(ColorToken.secondaryBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

public extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
