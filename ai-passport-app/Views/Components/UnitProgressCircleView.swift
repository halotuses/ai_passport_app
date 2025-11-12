import SwiftUI

struct UnitProgressCircleView: View {
    let answeredCount: Int
    let totalCount: Int
    let correctCount: Int
    let incorrectCount: Int

    private var sanitizedTotal: Int {
        max(totalCount, 0)
    }

    private var sanitizedAnswered: Int {
        guard sanitizedTotal > 0 else { return 0 }
        let clampedAnswered = min(max(answeredCount, 0), sanitizedTotal)
        return max(clampedAnswered, sanitizedCorrect + sanitizedIncorrect)
    }

    private var sanitizedCorrect: Int {
        guard sanitizedTotal > 0 else { return 0 }
        return min(max(correctCount, 0), sanitizedTotal)
    }

    private var sanitizedIncorrect: Int {
        guard sanitizedTotal > 0 else { return 0 }
        let allowedIncorrect = sanitizedTotal - sanitizedCorrect
        return min(max(incorrectCount, 0), allowedIncorrect)
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

    private var incorrectProgress: Double {
        guard sanitizedTotal > 0 else { return 0 }
        return Double(sanitizedIncorrect) / Double(sanitizedTotal)
    }

    private var correctProgress: Double {
        guard sanitizedTotal > 0 else { return 0 }
        return Double(sanitizedCorrect) / Double(sanitizedTotal)
    }

    private var textColor: Color {
        sanitizedAnswered > 0 ? .themeTextPrimary : .themeTextSecondary
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundGradient)

            if progress > 0 {
                Circle()
                    .trim(from: 0, to: CGFloat(min(incorrectProgress, 1)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.themeIncorrect.opacity(0.85), Color.themeIncorrect]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: incorrectProgress)

                Circle()
                    .trim(
                        from: CGFloat(min(incorrectProgress, 1)),
                        to: CGFloat(min(incorrectProgress + correctProgress, 1))
                    )
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.themeCorrect.opacity(0.9), Color.themeCorrect]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.35), value: correctProgress)
            }

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
            UnitProgressCircleView(answeredCount: 18, totalCount: 20, correctCount: 15, incorrectCount: 3)
            UnitProgressCircleView(answeredCount: 3, totalCount: 20, correctCount: 2, incorrectCount: 1)
            UnitProgressCircleView(answeredCount: 0, totalCount: 0, correctCount: 0, incorrectCount: 0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
