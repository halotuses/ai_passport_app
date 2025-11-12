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

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
                .opacity(progress > 0 ? 1 : 0)
                .animation(.easeInOut(duration: 0.35), value: progress)

            Circle()
                .inset(by: 7)
                .fill(Color.white.opacity(0.12))

            Circle()
                .stroke(Color.white.opacity(0.16), lineWidth: 1)

            VStack(spacing: 1) {
                Text("\(sanitizedAnswered)")
                    .font(.system(size: 13, weight: .semibold))
                Text("/\(sanitizedTotal)")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(textColor)
        }
        .frame(width: 44, height: 44)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("学習進捗")
        .accessibilityValue("\(sanitizedAnswered)問中\(sanitizedTotal)問を解答済み")
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
