import SwiftUI
#if os(iOS)
import UIKit
#endif

/// 下部タブバーのビュー
/// - ホーム / ブックマーク / 設定 の3つのタブを表示
/// - グラデーション背景を下端まで塗りつぶし、SafeAreaに対応
struct BottomTabBarView: View {
    // ルーティング制御（Navigation管理）
    @EnvironmentObject private var router: NavigationRouter
    // 画面状態管理（メインタブの切り替えなど）
    @EnvironmentObject private var mainViewState: MainViewState
    var onTapSettings: () -> Void = {}

    // iOSとmacOSでHover挙動を分ける
#if os(iOS)
    @State private var isHovering = true
#else
    @State private var isHovering = false
#endif
    
    // タブバー内部要素の高さ
    private let tabBarContentHeight: CGFloat = 40
    // 各アイコンの上余白
    private let tabItemTopPadding: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景グラデーション（全幅・下端まで）
            backgroundGradient
                .frame(maxWidth: .infinity)
                .frame(height: totalHeight)
                .ignoresSafeArea(edges: .bottom)
                .zIndex(0)
            
            // --- タブアイコン群 ---
            HStack {
                Spacer()
                
                // 🏠 ホームタブ
                Button(action: {
                    guard isHomeButtonEnabled else { return }
                    withAnimation {
                        mainViewState.reset(router: router)
                    }
                }) {
                    VStack {
                        Image(systemName: "house.fill")
                        Text("ホーム")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, tabItemTopPadding)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isHovering && isHomeButtonEnabled)
                .foregroundColor(mainViewState.isOnHome && !mainViewState.isShowingBookmarks ? .white : .white.opacity(0.75))
                
                Spacer()
                
                // 🔖 ブックマークタブ
                Button(action: {
                    guard isBookmarksButtonEnabled else { return }
                    withAnimation {
                        mainViewState.enterBookmarks(router: router)
                    }
                }) {
                    VStack {
                        Image(systemName: "bookmark.fill")
                        Text("ブックマーク")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, tabItemTopPadding)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isHovering && isBookmarksButtonEnabled)
                .foregroundColor(mainViewState.isShowingBookmarks ? .white : .white.opacity(0.75))
                
                Spacer()
                
                // ⚙️ 設定タブ
                Button(action: {
                    onTapSettings()
                }) {
                    VStack {
                        Image(systemName: "gearshape.fill")
                        Text("設定")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, tabItemTopPadding)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isHovering)
                .foregroundColor(.white.opacity(0.75))
                
                Spacer()
            }
            // --- タブバー全体のレイアウト調整 ---
            .frame(height: tabBarContentHeight)
            .frame(maxWidth: .infinity)
            .padding(.bottom, safeAreaInsetsBottom)
            .background(tabBarBackground)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .frame(height: totalHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        // Hover（mac用）でフェード表示切り替え
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

extension BottomTabBarView {
    /// SafeArea込みの合計高さ
    private var totalHeight: CGFloat {
        tabBarContentHeight + safeAreaInsetsBottom
    }
    
    /// ホームボタンの押下可否
    private var isHomeButtonEnabled: Bool {
        !(mainViewState.isOnHome && !mainViewState.isShowingBookmarks)
    }

    /// ブックマークボタンの押下可否
    private var isBookmarksButtonEnabled: Bool {
        !mainViewState.isShowingBookmarks
    }

    /// グラデーションの定義（全体背景）
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeNavigationEnd, Color.themeNavigationStart],
            startPoint: UnitPoint(x: 0.15, y: 0.0),
            endPoint: UnitPoint(x: 0.85, y: 1.0)
        )
    }

    /// タブバー背景（角丸＋影付き）
    private var tabBarBackground: some View {
        TopRoundedRectangle(radius: 10)
            .fill(backgroundGradient)
            .shadow(color: Color.themeNavigationEnd.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Safe Area Helpers
private extension BottomTabBarView {
    /// iPhoneのSafeAreaInsetを動的取得
    /// - ホームインジケータ領域などを考慮
    var safeAreaInsetsBottom: CGFloat {
#if os(iOS)
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first,
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            return 0
        }
        return window.safeAreaInsets.bottom
#else
        return 0
#endif
    }
}

/// 上部だけ角丸の矩形シェイプ
/// - タブバーの背景用
private struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cornerRadius = min(min(radius, height / 2), width / 2)

        // 左下から描画スタート
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        // 左上の角丸
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        // 右上の角丸
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        // 右下に戻る
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
