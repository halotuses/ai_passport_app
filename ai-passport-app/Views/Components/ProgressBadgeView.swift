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

    private var accuracyText: String {
        guard answeredCount > 0 else { return "--%" }
        return "\(Int((clampedAccuracy * 100).rounded()))%"
    }


    private var correctSummaryText: String {
        if answeredCount > 0 {
            return "正答数 \(correctCount)/\(answeredCount)"
        }
        if totalCount > 0 {
            return "正答数 \(correctCount)/\(totalCount)"
        }
        return "正答数 0/0"
    }
    
    private var incorrectCount: Int {
        max(answeredCount - correctCount, 0)
    }

    private var incorrectSummaryText: String {
        if answeredCount > 0 {
            return "不正解数 \(incorrectCount)/\(answeredCount)"
        }
        if totalCount > 0 {
            return "不正解数 \(incorrectCount)/\(totalCount)"
        }
        return "不正解数 0/0"
    }

    private var unansweredCount: Int {
        max(totalCount - answeredCount, 0)
    }

    private var unansweredSummaryText: String {
        if totalCount > 0 {
            return "未解答数 \(unansweredCount)/\(totalCount)"
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
        totalCount > 0 && correctCount == totalCount
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
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.themeSurface.opacity(0.7))
                    Capsule()
                        .fill(progressGradient)
                        .frame(width: geometry.size.width * clampedAccuracy)
                        .animation(.easeInOut(duration: 0.45), value: clampedAccuracy)
                }
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
