import SwiftUI

struct BottomTabBarView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
#if os(iOS)
    @State private var isHovering = true
#else
    @State private var isHovering = false
#endif
    
    private let tabBarContentHeight: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .top) {
            backgroundGradient
                .frame(maxWidth: .infinity)
                .frame(height: totalHeight)
                .ignoresSafeArea(edges: .bottom)
                .zIndex(0)
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
            .frame(height: tabBarContentHeight)
            .frame(maxWidth: .infinity)
            .padding(.bottom, safeAreaInsets.bottom)
            .background(tabBarBackground)
            .opacity(isHovering ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .frame(height: totalHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())

        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }
}

extension BottomTabBarView {
    private var totalHeight: CGFloat {
        tabBarContentHeight + safeAreaInsets.bottom
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color.themeSecondary, Color.themeMain],
            startPoint: UnitPoint(x: 0.2, y: 0.0),
            endPoint: UnitPoint(x: 0.8, y: 1.0)
        )
    }
    private var tabBarBackground: some View {
        TopRoundedRectangle(radius: 10)
            .fill(backgroundGradient)
            .shadow(color: Color.themeSecondary.opacity(0.25), radius: 16, x: 0, y: 8)
    }
}

private struct TopRoundedRectangle: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cornerRadius = min(min(radius, height / 2), width / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

