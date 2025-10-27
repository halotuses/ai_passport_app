import SwiftUI

/// アプリのルートコンテナ。起動直後はスプラッシュ画面を表示し、
/// 一定時間経過後にメインフレームへフェード遷移する。
struct RootContainerView: View {
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if isShowingSplash {
                SplashSumusView {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
            } else {
                AppFrameView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isShowingSplash)
    }
}

#Preview {
    RootContainerView()
        .environmentObject(ProgressManager())
}
