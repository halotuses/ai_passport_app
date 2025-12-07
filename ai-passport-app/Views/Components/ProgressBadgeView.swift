import SwiftUI

/// 章選択画面での学習状況を示すバッジスタイルのプログレスビュー
struct ProgressBadgeView: View {
    let correctCount: Int
    let answeredCount: Int
    let totalCount: Int
    let accuracy: Double
    
    private var incorrectCount: Int { max(answeredCount - correctCount, 0) }
    private var unansweredCount: Int {
        guard totalCount > 0 else { return 0 }
        return max(totalCount - answeredCount, 0)
    }

    private var clampedAccuracy: Double {
        min(max(accuracy, 0), 1)
    }

    private var accuracyText: String {
        guard answeredCount > 0 else { return "--%" }
        return "\(Int((clampedAccuracy * 100).rounded()))%"
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

    
    private var accuracyForegroundStyle: AnyShapeStyle {
        if isPerfectScore {
            return AnyShapeStyle(Color.crownGoldDeep)
        }

        return AnyShapeStyle(Color.themeSecondary)
    }

    private var correctProgress: Double {
        guard totalCount > 0 else { return 0 }
        return min(max(Double(correctCount) / Double(totalCount), 0), 1)
    }

    private var incorrectProgress: Double {
        guard totalCount > 0 else { return 0 }
        return min(max(Double(incorrectCount) / Double(totalCount), 0), 1)
    }

    private var correctBarGradient: LinearGradient {
        if isPerfectScore {
            return .crownGold
        }

        return LinearGradient(
            colors: [Color.themeCorrect.opacity(0.85), Color.themeCorrect],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var incorrectBarGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeIncorrect.opacity(0.85), Color.themeIncorrect],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var unansweredLabelText: String {
        guard totalCount > 0 else { return "未回答 0問" }
        return "未回答 \(unansweredCount)問"
    }
    private var correctLabelText: String { "正解 \(correctCount)問" }

      private var incorrectLabelText: String { "不正解 \(incorrectCount)問" }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                statusTag(color: .themeCorrect, text: correctLabelText)
                statusTag(color: .themeIncorrect, text: incorrectLabelText)
                statusTag(color: .gray, text: unansweredLabelText)
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
                    if incorrectProgress > 0 {
                        Capsule()
                            .fill(incorrectBarGradient)
                            .frame(width: geometry.size.width * incorrectProgress)
                            .animation(.easeInOut(duration: 0.45), value: incorrectProgress)
                    }

                    if correctProgress > 0 {
                        Capsule()
                            .fill(correctBarGradient)
                            .frame(width: geometry.size.width * correctProgress)
                            .offset(x: geometry.size.width * incorrectProgress)
                            .animation(.easeInOut(duration: 0.45), value: correctProgress + incorrectProgress)
                    }
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
    private func statusTag(color: Color, text: String) -> some View {
         HStack(spacing: 6) {
             Circle()
                 .fill(color.opacity(0.9))
                 .frame(width: 10, height: 10)
             Text(text)
                 .font(.system(size: 12, weight: .medium))
                 .foregroundColor(.themeTextPrimary)
         }
         .padding(.horizontal, 10)
         .padding(.vertical, 6)
         .background(
             Capsule()
                 .fill(Color.themeSurface.opacity(0.8))
         )
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
