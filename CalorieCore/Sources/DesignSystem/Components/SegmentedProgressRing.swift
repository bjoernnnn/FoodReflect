import SwiftUI

/// Ein Segment des Rings: Anteilswert (z. B. konsumierte kcal eines Makros) + Farbe.
public struct RingSegment: Equatable, Sendable {
    public let value: Double
    public let color: Color

    public init(value: Double, color: Color) {
        self.value = value
        self.color = color
    }
}

/// Mehrfarbiger Fortschrittsring: jedes Makro bekommt seinen Anteil an den konsumierten
/// kcal als eigenes Segment, gestapelt gegen einen gemeinsamen Referenzwert (Tagesziel).
/// Überschreitet die Summe der Segmente das Ziel, wird der überschießende Anteil als
/// eigener, warnfarbener Bogen sichtbar gemacht statt die Segmente einfach zu stauchen.
public struct SegmentedProgressRing: View {
    private let segments: [RingSegment]
    private let total: Double
    private let lineWidth: CGFloat
    /// Startet bei 0 und animiert beim ersten Erscheinen auf 1 hoch, damit der Ring sichtbar
    /// „einschwingt" statt sofort mit dem fertigen Wert dazustehen.
    @State private var appearProgress: Double = 0

    public init(segments: [RingSegment], total: Double, lineWidth: CGFloat = 14) {
        self.segments = segments
        self.total = total
        self.lineWidth = lineWidth
    }

    private var sumOfSegments: Double {
        segments.reduce(0) { $0 + $1.value }
    }

    private var isOverTarget: Bool {
        total > 0 && sumOfSegments > total
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(ColorToken.secondaryBackground, lineWidth: lineWidth)

            ForEach(Array(segmentArcs.enumerated()), id: \.offset) { _, arc in
                Circle()
                    .trim(from: arc.start * appearProgress, to: arc.end * appearProgress)
                    .stroke(arc.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .animation(.easeInOut, value: segmentArcs)
        .animation(.easeOut(duration: 0.8), value: appearProgress)
        .onAppear { appearProgress = 1 }
        .accessibilityLabel("Makro-Fortschritt")
        .accessibilityValue(isOverTarget ? "Tagesziel überschritten" : "\(Int(sumOfSegments)) von \(Int(total)) Kalorien")
    }

    private struct Arc: Equatable {
        let start: Double
        let end: Double
        let color: Color
    }

    /// Solange die Summe unter dem Ziel liegt, sind Segmente proportional zum Ziel groß
    /// (Ring bleibt unvollständig, Rest zeigt den Track). Bei Überschreitung skaliert die
    /// Summe selbst als Referenz (Ring wird voll) und der Übertrag wird als letzter,
    /// warnfarbener Bogen angehängt.
    private var segmentArcs: [Arc] {
        let sum = sumOfSegments
        guard sum > 0 else { return [] }
        let effectiveTotal = max(total, sum)

        var cursor = 0.0
        var arcs: [Arc] = []
        for segment in segments where segment.value > 0 {
            let fraction = segment.value / effectiveTotal
            let start = cursor
            let end = min(cursor + fraction, 1.0)
            arcs.append(Arc(start: start, end: end, color: segment.color))
            cursor = end
        }

        if isOverTarget, total > 0 {
            arcs.append(Arc(start: total / sum, end: 1.0, color: ColorToken.warning))
        }
        return arcs
    }
}

#Preview("Im Ziel") {
    SegmentedProgressRing(
        segments: [
            RingSegment(value: 300, color: ColorToken.proteinColor),
            RingSegment(value: 500, color: ColorToken.carbsColor),
            RingSegment(value: 200, color: ColorToken.fatColor)
        ],
        total: 2000
    )
    .frame(width: 220, height: 220)
    .padding()
}

#Preview("Über dem Ziel") {
    SegmentedProgressRing(
        segments: [
            RingSegment(value: 900, color: ColorToken.proteinColor),
            RingSegment(value: 900, color: ColorToken.carbsColor),
            RingSegment(value: 600, color: ColorToken.fatColor)
        ],
        total: 2000
    )
    .frame(width: 220, height: 220)
    .padding()
}
