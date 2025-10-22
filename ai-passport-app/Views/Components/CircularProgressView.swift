import SwiftUI

/// 章ごとの進捗を表示するバッジ
struct ProgressBadgeView: View {
    let correctCount: Int
    let totalCount: Int
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var percentageText: String {
        guard totalCount > 0 else { return "--%" }
        let percentage = Int((clampedProgress * 100).rounded())
        return "\(percentage)%"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("\(correctCount)/\(totalCount)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeTextPrimary)

            ProgressView(value: clampedProgress)
                .progressViewStyle(.linear)
                .tint(.themeMain)
                .frame(maxWidth: .infinity)

            Text(percentageText)
                .font(.caption.weight(.semibold))
                .foregroundColor(.themeSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.themeSecondary.opacity(0.15))
                )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.45), radius: 10, x: 0, y: 4)
    }
}
