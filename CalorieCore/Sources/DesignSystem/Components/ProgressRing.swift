import SwiftUI

/// Kreisförmiger Fortschrittsring für die Rest-kcal-Anzeige.
public struct ProgressRing: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let tint: Color

    public init(progress: Double, lineWidth: CGFloat = 14, tint: Color = ColorToken.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(ColorToken.secondaryBackground, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

#Preview {
    ProgressRing(progress: 0.65)
        .frame(width: 200, height: 200)
        .padding()
}
