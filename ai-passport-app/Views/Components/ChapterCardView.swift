import SwiftUI

/// 共通の章カードビュー。章タイトルと進捗バッジを表示する。
struct ChapterCardView<ViewModel: ChapterProgressDisplayable>: View {
    @ObservedObject var viewModel: ViewModel
    var isDisabled: Bool = false
    var badgeDisplayMode: ProgressBadgeView.DisplayMode = .detailed
    
    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeMain, Color.themeSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconGradient)
                .opacity(isDisabled ? 0.4 : 1.0)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                    .opacity(isDisabled ? 0.6 : 1.0)
                if let pair = viewModel.wordPair, !pair.isEffectivelyEmpty {
                    Text(pair.displayText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .opacity(isDisabled ? 0.6 : 1.0)
                }
            }

            Spacer()

            ProgressBadgeView(
                correctCount: viewModel.correctCount,
                answeredCount: viewModel.answeredCount,
                totalCount: viewModel.totalQuestions,
                accuracy: viewModel.accuracyRate,
                displayMode: badgeDisplayMode
            )
            .allowsHitTesting(false)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(backgroundGradient)
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 6)
        .overlay(disabledOverlay)
        .opacity(isDisabled ? 0.55 : 1.0)
    }

    @ViewBuilder
    private var disabledOverlay: some View {
        if isDisabled {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.04))
        }
    }
}
