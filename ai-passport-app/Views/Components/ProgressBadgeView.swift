import SwiftUI

/// 章選択画面での学習状況を示すバッジスタイルのプログレスビュー
struct ProgressBadgeView: View {
    let correctCount: Int
    let answeredCount: Int
    let totalCount: Int
    let accuracy: Double

    private var clampedAccuracy: Double {
        min(max(accuracy, 0), 1)
    }
    
    private var totalQuestionCount: Int {
        max(totalCount, 0)
    }

    private var sanitizedCorrectCount: Int {
        min(max(correctCount, 0), totalQuestionCount)
    }

    private var sanitizedAnsweredCount: Int {
        min(max(answeredCount, 0), totalQuestionCount)
    }

    private var sanitizedIncorrectCount: Int {
        max(sanitizedAnsweredCount - sanitizedCorrectCount, 0)
    }

    private var sanitizedUnansweredCount: Int {
        max(totalQuestionCount - sanitizedAnsweredCount, 0)
    }

    private var accuracyText: String {
        guard sanitizedAnsweredCount > 0 else { return "--%" }
        return "\(Int((clampedAccuracy * 100).rounded()))%"
    }


    private var correctSummaryText: String {
        if sanitizedAnsweredCount > 0 {
            return "正答数 \(sanitizedCorrectCount)/\(sanitizedAnsweredCount)"
        }
        if totalQuestionCount > 0 {
            return "正答数 \(sanitizedCorrectCount)/\(totalQuestionCount)"
        }
        return "正答数 0/0"
    }
    
    private var incorrectCount: Int {
        sanitizedIncorrectCount
    }

    private var incorrectSummaryText: String {
        if sanitizedAnsweredCount > 0 {
            return "不正解数 \(incorrectCount)/\(sanitizedAnsweredCount)"
        }
        if totalQuestionCount > 0 {
            return "不正解数 \(incorrectCount)/\(totalQuestionCount)"
        }
        return "不正解数 0/0"
    }

    private var unansweredCount: Int {
        sanitizedUnansweredCount
    }

    private var unansweredSummaryText: String {
        if totalQuestionCount > 0 {
            return "未解答数 \(unansweredCount)/\(totalQuestionCount)"
        }
        return "未解答数 0/0"
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var isPerfectScore: Bool {
        totalQuestionCount > 0 && sanitizedCorrectCount == totalQuestionCount
    }

    
    private var progressGradient: LinearGradient {
        if isPerfectScore {
            return .crownGold
        }

        return LinearGradient(
            colors: [Color.themeMain, Color.themeSecondary.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var accuracyForegroundStyle: AnyShapeStyle {
        if isPerfectScore {
            return AnyShapeStyle(Color.crownGoldDeep)
        }

        return AnyShapeStyle(Color.themeSecondary)
    }
    
    private var correctFraction: Double {
        progressFraction(for: sanitizedCorrectCount)
    }

    private var incorrectFraction: Double {
        progressFraction(for: sanitizedIncorrectCount)
    }

    private var unansweredFraction: Double {
        progressFraction(for: sanitizedUnansweredCount)
    }

    private func progressFraction(for count: Int) -> Double {
        guard totalQuestionCount > 0 else { return 0 }
        return Double(count) / Double(totalQuestionCount)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(correctSummaryText)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.themeTextPrimary)
                    Text(incorrectSummaryText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.themeTextSecondary)
                    Text(unansweredSummaryText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.themeTextSecondary)
                }
                Spacer()
                Text(accuracyText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accuracyForegroundStyle)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.themeBadgeBackground.opacity(0.5))
                    )
            }

            GeometryReader { geometry in
                segmentedProgressBar(width: geometry.size.width)
            }
            .frame(height: 8)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(badgeGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.5), radius: 10, x: 0, y: 6)
    }
    @ViewBuilder
    private func segmentedProgressBar(width: CGFloat) -> some View {
        let correctWidth = width * correctFraction
        let incorrectWidth = width * incorrectFraction
        let unansweredWidth = width * unansweredFraction

        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.themeSurface.opacity(0.7))

            HStack(spacing: 0) {
                if correctWidth > 0 {
                    segment(width: correctWidth, fill: progressGradient)
                        .animation(.easeInOut(duration: 0.45), value: correctFraction)
                }
                if incorrectWidth > 0 {
                    segment(width: incorrectWidth, fill: Color.themeIncorrect)
                        .animation(.easeInOut(duration: 0.45), value: incorrectFraction)
                }
                if unansweredWidth > 0 {
                    segment(width: unansweredWidth, fill: Color.themeTextSecondary.opacity(0.28))
                        .animation(.easeInOut(duration: 0.45), value: unansweredFraction)
                }
            }
            .mask(Capsule())
        }
    }

    private func segment(width: CGFloat, fill: some ShapeStyle) -> some View {
        Rectangle()
            .fill(fill)
            .frame(width: width)
    }
}

struct ProgressBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ProgressBadgeView(correctCount: 3, answeredCount: 4, totalCount: 5, accuracy: 0.75)
            ProgressBadgeView(correctCount: 0, answeredCount: 0, totalCount: 5, accuracy: 0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
