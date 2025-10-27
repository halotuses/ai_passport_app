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

                        Text("®")
                            .font(.system(size: logoSize * 0.16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.85))
                            .offset(x: logoSize * 0.1, y: -logoSize * 0.12)
                    }

                    Text("SUMUS")
                        .font(.system(size: wordmarkSize, weight: .heavy, design: .rounded))
                        .kerning(2)
                        .foregroundStyle(.black)
                        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 8)
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
        Color(red: 0 / 255, green: 152 / 255, blue: 69 / 255),    // green
        Color(red: 0 / 255, green: 114 / 255, blue: 206 / 255),   // blue
        Color(red: 255 / 255, green: 163 / 255, blue: 0 / 255),   // orange
        Color(red: 229 / 255, green: 28 / 255, blue: 35 / 255)    // red
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cornerRadius = size * 0.16
            let crossThickness = size * 0.28
            let centerSquareSize = size * 0.28
            let centerInnerSize = size * 0.14
            let crossBorderWidth = size * 0.024

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black, lineWidth: size * 0.024)
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

                SumusCrossShape(thickness: crossThickness)
                    .fill(Color.white)
                    .overlay(
                        SumusCrossShape(thickness: crossThickness)
                            .stroke(Color.black, lineWidth: crossBorderWidth)
                    )

                Rectangle()
                    .fill(Color.white)
                    .frame(width: centerSquareSize, height: centerSquareSize)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: crossBorderWidth)
                    )

                Rectangle()
                    .fill(Color.black)
                    .frame(width: centerInnerSize, height: centerInnerSize)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct SumusCrossShape: Shape {
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfThickness = thickness / 2

        var path = Path()

        path.addRect(
            CGRect(
                x: rect.minX,
                y: center.y - halfThickness,
                width: rect.width,
                height: thickness
            )
        )

        path.addRect(
            CGRect(
                x: center.x - halfThickness,
                y: rect.minY,
                width: thickness,
                height: rect.height
            )
        )

        return path
    }
}

#Preview {
    SplashSumusView()
        .frame(width: 390, height: 844)
}
