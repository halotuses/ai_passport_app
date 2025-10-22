import SwiftUI

/// 章選択画面での学習状況を示すバッジスタイルのプログレスビュー
struct ProgressBadgeView: View {
    let correctCount: Int
    let totalCount: Int
    let progress: Double

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var progressText: String {
        guard totalCount > 0 else { return "--%" }
        return "\(Int((clampedProgress * 100).rounded()))%"
    }

    private var badgeGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeMain, Color.themeSecondary.opacity(0.85)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(correctCount)/\(totalCount)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.themeTextPrimary)
                Spacer()
                Text(progressText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.themeSecondary)
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
                        .frame(width: geometry.size.width * clampedProgress)
                        .animation(.easeInOut(duration: 0.45), value: clampedProgress)
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
            ProgressBadgeView(correctCount: 3, totalCount: 5, progress: 0.6)
            ProgressBadgeView(correctCount: 0, totalCount: 0, progress: 0)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
