import SwiftUI

/// 画面共通ヘッダー
/// - 各画面上部にタイトルと戻るボタンを表示
/// - MainViewState と NavigationRouter により制御される
struct HeaderView: View {
    // 画面全体の状態を管理（タイトル・ボタン表示など）
    @EnvironmentObject private var mainViewState: MainViewState
    // ルーティング管理（画面遷移を制御）
    @EnvironmentObject private var router: NavigationRouter
    @ScaledMetric(relativeTo: .title2) private var headerHeight: CGFloat = 48

    var body: some View {
        let needsSidePadding = (mainViewState.headerBackButton != nil) || (mainViewState.headerBookmark != nil)

        return ZStack {
            // MARK: - タイトル部分
            // タイトル文字列は MainViewState.headerTitle から取得
            Text(mainViewState.headerTitle)
                .font(.title2)
                .fontWeight(.bold)
                .lineLimit(1) // 長いタイトルを1行に制限
                .minimumScaleFactor(0.7) // 幅が足りない場合に縮小
                .allowsTightening(true) // 文字間を詰めて収まりやすく
                .frame(maxWidth: .infinity)
            // 戻る・ブックマークボタンがある場合は左右に余白を確保
            .padding(.horizontal, needsSidePadding ? 88 : 20)

            // MARK: - 左側の戻るボタンエリア
            HStack {
                if let backButton = mainViewState.headerBackButton {
                    // 戻るボタンを表示（MainViewStateが保持する設定に基づく）
                    Button(action: mainViewState.makeBackButtonAction(for: backButton, router: router)) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text(backButton.title)
                                .font(.body)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.18)) // 背景に半透明の白を適用
                        .cornerRadius(12)
                    }
                    .foregroundColor(.white) // ボタン文字とアイコンを白で統一
                    .accessibilityLabel(backButton.title) // VoiceOver対応
                }

                Spacer() // 左にボタンを寄せる
            }
            // MARK: - 右側のブックマークボタンエリア
            HStack {
                Spacer()

                if let bookmark = mainViewState.headerBookmark {
                    Button(action: bookmark.action) {
                        Image(systemName: bookmark.isActive ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(bookmark.isActive ? .yellow : Color.yellow.opacity(0.6))
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(bookmark.isActive ? "ブックマーク済み" : "ブックマーク")
                    .accessibilityAddTraits(bookmark.isActive ? .isSelected : [])
                }
            }
        }
        // MARK: - レイアウト全体設定
        .padding(.horizontal, 16)
        .frame(height: headerHeight)
        .frame(maxWidth: .infinity)

        // MARK: - 背景スタイル
        .background(
            LinearGradient(
                colors: [Color.themeMain, Color.themeSecondary], // 左→右のグラデーション
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(.white)
        // 下方向に柔らかい影
        .shadow(
            color: Color.themeSecondary.opacity(0.25),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}
