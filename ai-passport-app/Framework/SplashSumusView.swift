import SwiftUI

/// Luxurious SUMUS™ splash screen rendered entirely with SwiftUI vectors.
struct SplashSumusView: View {
    @State private var isVisible = false

    private let backgroundColor = Color(red: 0xF2 / 255, green: 0xF8 / 255, blue: 0xED / 255)
    private let animationDuration: TimeInterval = 0.8
    private let autoDismissDelay: TimeInterval = 1.5

    var onFinished: (() -> Void)?

    init(onFinished: (() -> Void)? = nil) {
        self.onFinished = onFinished
    }

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
                        .font(.system(size: wordmarkSize, weight: .black, design: .default))
                        .kerning(-1)
                        .foregroundStyle(.black)
                        .shadow(color: .black.opacity(0.25), radius: 4, x: 1, y: 3)
                        .overlay(alignment: .topTrailing) {
                            Text("™")
                                .font(.system(size: wordmarkSize * 0.32, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                                .offset(
                                    x: max(wordmarkSize * 0.06, 4),
                                    y: -max(wordmarkSize * 0.2, 10)
                                )
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
            .animation(.easeOut(duration: animationDuration), value: isVisible)
            .onAppear {
                guard !isVisible else { return }
                isVisible = true
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                    onFinished?()
                }
            }
        }
    }
}

private struct SumusLogoMark: View {
    private let quadrantColors: [Color] = [
        Color(red: 0x31 / 255, green: 0xC0 / 255, blue: 0x4D / 255),   // green
        Color(red: 0x00 / 255, green: 0xAE / 255, blue: 0xEF / 255),   // blue
        Color(red: 0xFF / 255, green: 0xB0 / 255, blue: 0x00 / 255),   // orange
        Color(red: 0xE9 / 255, green: 0x4A / 255, blue: 0x2F / 255)    // red
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let cornerRadius = size * 0.10
            let crossThickness = size * 0.18
            let centerSquareSize = size * 0.23
            let centerInnerSize = size * 0.12
            let strokeWidth = size * 0.015

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.black, lineWidth: strokeWidth)
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
                    .fill(Color.black)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: centerSquareSize, height: centerSquareSize)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: strokeWidth)
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
