import SwiftUI

/// 章選択画面での学習状況を示すバッジスタイルのプログレスビュー
struct ProgressBadgeView: View {
    
    enum DisplayMode {
        case detailed
        case ratio
    }
    
    
    let correctCount: Int
    let answeredCount: Int
    let totalCount: Int
    let accuracy: Double
    var bookmarkCount: Int = 0
    var displayMode: DisplayMode = .detailed
    
    private var clampedAccuracy: Double {
        min(max(accuracy, 0), 1)
    }

    private var accuracyText: String {
        guard answeredCount > 0 else { return "--%" }
        return "\(Int((clampedAccuracy * 100).rounded()))%"
    }



    
    private var incorrectCount: Int {
        max(answeredCount - correctCount, 0)
    }



    private var unansweredCount: Int {
        max(totalCount - answeredCount, 0)
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
    
    private var ratioText: String {
        guard totalCount > 0 else { return "--/--" }
        return "\(correctCount)/\(totalCount)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch displayMode {
            case .detailed:
                detailedContent
            case .ratio:
                ratioContent
            }
        }
        .padding(.vertical, 12)
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

    private var detailedContent: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 8) {
                compactStatistic(symbol: "checkmark.circle.fill", value: correctCount, tint: .themeCorrect, accessibilityLabel: "正答数")
                compactStatistic(symbol: "xmark.circle.fill", value: incorrectCount, tint: .themeIncorrect, accessibilityLabel: "不正解数")
                compactStatistic(symbol: "circle", value: unansweredCount, tint: .themeTextSecondary, accessibilityLabel: "未解答数")
                compactStatistic(symbol: "bookmark.fill", value: bookmarkCount, tint: .themeAccent, accessibilityLabel: "ブックマーク数")
                Spacer()
                Text(accuracyText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accuracyForegroundStyle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.themeBadgeBackground.opacity(0.5)))
                    .frame(minWidth: 50)
                    .fixedSize(horizontal: true, vertical: false)
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
            .frame(height: 7)
        }
    }

    private func compactStatistic(
        symbol: String,
        value: Int,
        tint: Color,
        accessibilityLabel: String
    ) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(tint)
            Text("\(value)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.themeTextPrimary)
                .monospacedDigit()
        }
        .frame(minWidth: 20)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(value)")
    }

    private var ratioContent: some View {
        HStack {
            Text(ratioText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.themeTextPrimary)
                .monospacedDigit()
            Spacer()
        }
        .frame(minWidth: 100)
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
