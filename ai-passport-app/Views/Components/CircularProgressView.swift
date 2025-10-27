import SwiftUI

/// ホーム画面で全体の学習状況を示す円形プログレスビュー
struct CircularProgressView: View {
    struct Segment: Identifiable {
        enum Kind: Hashable {
            case correct
            case incorrect
            case unanswered
        }

        let kind: Kind
        let value: Double
        let color: Color

        var id: Kind { kind }
    }

    private struct SegmentSlice: Identifiable {
        let segment: Segment
        let startAngle: Angle
        let endAngle: Angle
        let endFraction: Double

        var id: Segment.Kind { segment.id }
    }
    private struct RingSegment: Shape {
        var startAngle: Angle
        var endAngle: Angle
        var clockwise: Bool = true

        func path(in rect: CGRect) -> Path {
            let rotationAdjustment = Angle.degrees(90)
            let adjustedStart = startAngle - rotationAdjustment
            let adjustedEnd = endAngle - rotationAdjustment
            let radius = min(rect.width, rect.height) / 2
            let center = CGPoint(x: rect.midX, y: rect.midY)

            var path = Path()
            path.addArc(
                center: center,
                radius: radius,
                startAngle: adjustedStart,
                endAngle: adjustedEnd,
                clockwise: !clockwise
            )
            return path
        }
    }
    
    let segments: [Segment]
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 140
    
    private let layoutOrder: [Segment.Kind] = [.unanswered, .incorrect, .correct]
    private let drawingOrder: [Segment.Kind] = [.unanswered, .incorrect, .correct]

    private var sanitizedSegments: [Segment] {
        segments.map { segment in
            Segment(kind: segment.kind, value: max(segment.value, 0), color: segment.color)
        }
    }

    private func orderIndex(for kind: Segment.Kind, in order: [Segment.Kind]) -> Int {
        order.firstIndex(of: kind) ?? order.count
    }

    private var layoutSegments: [Segment] {
        sanitizedSegments.sorted { lhs, rhs in
            orderIndex(for: lhs.kind, in: layoutOrder) < orderIndex(for: rhs.kind, in: layoutOrder)
        }
    }

    
    private var totalValue: Double {
        sanitizedSegments.reduce(0) { $0 + $1.value }
    }
    

    private var segmentSlices: [SegmentSlice] {
        guard totalValue > 0 else { return [] }

        let epsilon = 0.1
        var slices: [SegmentSlice] = []
        var currentAngle: Double = 0
        
        for (index, segment) in segments.enumerated(){

            let fraction = segment.value / totalValue
                let sweep = fraction * 360
                let baseStartAngle = currentAngle
                let baseEndAngle = currentAngle + sweep
                let isFirst = index == 0
                let isLast = index == segments.count - 1

                let adjustedStart = isFirst ? baseStartAngle : baseStartAngle - epsilon
                let adjustedEnd = isLast ? baseEndAngle + epsilon : baseEndAngle
            slices.append(
                SegmentSlice(
                    segment: segment,
                    startAngle: .degrees(adjustedStart),
                    endAngle: .degrees(adjustedEnd),
                    endFraction: min(baseEndAngle / 360, 1)
                )
            )
            currentAngle = baseEndAngle
        }

        return slices
    }

    private var sanitizedProgress: Double? {
        guard !progress.isNaN, progress >= 0 else { return nil }
        return min(max(progress, 0), 1)
    }

    private var progressText: String {
        guard let sanitizedProgress else { return "--%" }
        return "\(Int((sanitizedProgress * 100).rounded()))%"
    }

    private var shouldDisplayPlaceholder: Bool {
        segmentSlices.isEmpty
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeSurfaceElevated.opacity(0.35), lineWidth: lineWidth)

            if shouldDisplayPlaceholder {
                Circle()
                    .stroke(Color.themeSurfaceElevated.opacity(0.2), lineWidth: lineWidth)
            } else {
                ForEach(segmentSlices.sorted { lhs, rhs in
                    orderIndex(for: lhs.segment.kind, in: drawingOrder) < orderIndex(for: rhs.segment.kind, in: drawingOrder)
                }) { slice in
                    RingSegment(startAngle: slice.startAngle, endAngle: slice.endAngle)
                        .stroke(
                            slice.segment.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .round)
                        )
                        .opacity(1.0)
                        .animation(.easeInOut(duration: 0.6), value: slice.endFraction)
                }
            }

            Text(progressText)
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(.themeTextPrimary)
        }
        .frame(width: size, height: size)
        .padding(lineWidth / 2)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.6), radius: 12, x: 0, y: 8)
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            CircularProgressView(
                segments: [
                    .init(kind: .correct, value: 12, color: .themeCorrect),
                    .init(kind: .incorrect, value: 3, color: .themeIncorrect),
                    .init(kind: .unanswered, value: 5, color: .themeButtonSecondary)
                ],
                progress: 0.68
            )
            CircularProgressView(
                segments: [
                    .init(kind: .correct, value: 0, color: .themeCorrect),
                    .init(kind: .incorrect, value: 0, color: .themeIncorrect),
                    .init(kind: .unanswered, value: 0, color: .themeButtonSecondary)
                ],
                progress: -1
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
