import SwiftUI

struct UnitProgressCircleView: View {
    let answeredCount: Int
    let totalCount: Int

    private var sanitizedTotal: Int {
        max(totalCount, 0)
    }

    private var sanitizedAnswered: Int {
        guard sanitizedTotal > 0 else { return 0 }
        return min(max(answeredCount, 0), sanitizedTotal)
    }

    private var progress: Double {
        guard sanitizedTotal > 0 else { return 0 }
        return Double(sanitizedAnswered) / Double(sanitizedTotal)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.themeSurfaceAlt.opacity(0.85),
                Color.themeSurfaceElevated.opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [Color.themeMain, Color.themeSecondary]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    private var textColor: Color {
        sanitizedAnswered > 0 ? .themeTextPrimary : .themeTextSecondary
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundGradient)

            PieProgressShape(progress: progress)
                .fill(progressGradient)
                .opacity(progress > 0 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: progress)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 1)

            VStack(spacing: 0) {
                Text("\(sanitizedAnswered)")
                    .font(.system(size: 12, weight: .semibold))
                Text("/\(sanitizedTotal)")
                    .font(.system(size: 9, weight: .medium))
                    .padding(.top, 1)
            }
            .foregroundStyle(textColor)
        }
        .frame(width: 44, height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("学習進捗")
        .accessibilityValue("\(sanitizedAnswered)問中\(sanitizedTotal)問を解答済み")
    }
}

private struct PieProgressShape: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let clampedProgress = min(max(progress, 0), 1)
        guard clampedProgress > 0 else {
            return Path()
        }

        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let endAngle = Angle(degrees: -90 + 360 * clampedProgress)

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

struct UnitProgressCircleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            UnitProgressCircleView(answeredCount: 18, totalCount: 20)
            UnitProgressCircleView(answeredCount: 3, totalCount: 20)
            UnitProgressCircleView(answeredCount: 0, totalCount: 0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
