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
        let start: Double
        let end: Double

        var id: Segment.Kind { segment.id }
    }

    let segments: [Segment]
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 140

    private var sanitizedSegments: [Segment] {
        segments.map { segment in
            Segment(kind: segment.kind, value: max(segment.value, 0), color: segment.color)
        }
    }

    private var totalValue: Double {
        sanitizedSegments.reduce(0) { $0 + $1.value }
    }
    

    private var segmentSlices: [SegmentSlice] {
        let segments = sanitizedSegments
        guard totalValue > 0 else { return [] }

        var slices: [SegmentSlice] = []
        var start: Double = 0

        for segment in segments {
            guard segment.value > 0 else { continue }

            let fraction = segment.value / totalValue
            let clampedEnd = min(start + fraction, 1)
            slices.append(
                SegmentSlice(
                    segment: segment,
                    start: start,
                    end: clampedEnd
                )
            )
            start = clampedEnd
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
                ForEach(segmentSlices) { slice in
                    Circle()
                        .trim(from: slice.start, to: slice.end)
                        .stroke(
                            slice.segment.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.6), value: slice.end)
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
