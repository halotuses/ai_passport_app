import SwiftUI

/// Luxurious SUMUS™ splash screen rendered entirely with SwiftUI vectors.
struct SplashSumusView: View {
    @State private var isVisible = false

    private let backgroundColor = Color(red: 242 / 255, green: 248 / 255, blue: 237 / 255)

    var body: some View {
        GeometryReader { proxy in
            let minDimension = min(proxy.size.width, proxy.size.height)
            let logoSize = minDimension * 0.33
            let wordmarkSize = minDimension * 0.11

            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: minDimension * 0.05) {
                    ZStack(alignment: .topTrailing) {
                        SumusLogoMark()
                            .frame(width: logoSize, height: logoSize)
                            .shadow(color: .black.opacity(0.25), radius: logoSize * 0.12, x: 0, y: logoSize * 0.08)

                        Text("®")
                            .font(.system(size: logoSize * 0.16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.75))
                            .offset(x: logoSize * 0.12, y: -logoSize * 0.12)
                    }

                    Text("SUMUS")
                        .font(.system(size: wordmarkSize, weight: .heavy, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(.black)
                        .shadow(color: .black.opacity(0.4), radius: 14, x: 0, y: 12)
                        .overlay(
                            LinearGradient(colors: [Color.white.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                                .blendMode(.screen)
                        )
                        .overlay(alignment: .topTrailing) {
                            Text("™")
                                .font(.system(size: wordmarkSize * 0.32, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                                .offset(x: wordmarkSize * 0.12, y: -wordmarkSize * 0.28)
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeIn(duration: 1.0), value: isVisible)
            .onAppear {
                isVisible = true
            }
        }
    }
}

private struct SumusLogoMark: View {
    private let quadrantColors: [Color] = [
        Color(red: 41 / 255, green: 178 / 255, blue: 94 / 255),   // green
        Color(red: 28 / 255, green: 137 / 255, blue: 226 / 255),  // blue
        Color(red: 247 / 255, green: 166 / 255, blue: 53 / 255),  // orange
        Color(red: 222 / 255, green: 47 / 255, blue: 47 / 255)    // red
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cornerRadius = size * 0.18
            let crossThickness = size * 0.27
            let crossLength = size * 0.82
            let centerOuterSize = size * 0.32
            let centerInnerSize = size * 0.18
            let crossBorderWidth = size * 0.025

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.25), radius: size * 0.1, x: 0, y: size * 0.05)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(LinearGradient(colors: [Color.white.opacity(0.8), Color.black.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: size * 0.02)
                    )

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(quadrantColors[0])
                        Rectangle()
                            .fill(quadrantColors[1])
                    }
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(quadrantColors[2])
                        Rectangle()
                            .fill(quadrantColors[3])
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                // white cross arms
                Rectangle()
                    .fill(Color.white)
                    .frame(width: crossLength, height: crossThickness)
                    .shadow(color: .black.opacity(0.08), radius: size * 0.04, x: 0, y: size * 0.02)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: crossThickness, height: crossLength)
                    .shadow(color: .black.opacity(0.08), radius: size * 0.04, x: 0, y: size * 0.02)

                // outer black border for cross arms
                CrossOutlineShape(thickness: crossThickness, length: crossLength)
                    .stroke(Color.black.opacity(0.55), lineWidth: crossBorderWidth)

                // central white square with black inset
                RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                    .fill(Color.white)
                    .frame(width: centerOuterSize, height: centerOuterSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.02, style: .continuous)
                            .fill(Color.black)
                            .frame(width: centerInnerSize, height: centerInnerSize)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                            .stroke(Color.black.opacity(0.55), lineWidth: crossBorderWidth)
                    )

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.4), lineWidth: size * 0.015)
                    .blendMode(.screen)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct CrossOutlineShape: Shape {
    let thickness: CGFloat
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfThickness = thickness / 2
        let halfLength = length / 2

        var path = Path()

        // Horizontal rectangle outline
        let horizontalRect = CGRect(
            x: center.x - halfLength,
            y: center.y - halfThickness,
            width: length,
            height: thickness
        )

        // Vertical rectangle outline
        let verticalRect = CGRect(
            x: center.x - halfThickness,
            y: center.y - halfLength,
            width: thickness,
            height: length
        )

        path.addRect(horizontalRect)
        path.addRect(verticalRect)

        return path
    }
}

#Preview {
    SplashSumusView()
        .frame(width: 390, height: 844)
}
