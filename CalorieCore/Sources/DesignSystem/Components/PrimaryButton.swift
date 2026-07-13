import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TypographyToken.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                ColorToken.accent.opacity(configuration.isPressed ? 0.8 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle {
        PrimaryButtonStyle()
    }
}
