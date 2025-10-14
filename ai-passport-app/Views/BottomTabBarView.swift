import SwiftUI

/// 下部タブバー（ダミー）
struct BottomTabBarView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var mainViewState: MainViewState
    
#if os(iOS)
    @State private var isHovering = true
#else
    @State private var isHovering = false
#endif
    
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: {
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
                }
                .buttonStyle(.plain)
                .allowsHitTesting(isHovering)
                .foregroundColor(.white)
                Spacer()
                
                VStack {
                    Image(systemName: "person.fill")
                    Text("アカウント")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .allowsHitTesting(isHovering)
                .foregroundColor(.white.opacity(0.8))
                Spacer()
                VStack {
                    Image(systemName: "gearshape.fill")
                    Text("設定")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .allowsHitTesting(isHovering)
                .foregroundColor(.white.opacity(0.8))
                Spacer()
                
            }
            .padding()

            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.themeSecondary, Color.themeMain],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color.themeSecondary.opacity(0.25), radius: 16, x: 0, y: 8)
            )
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}
