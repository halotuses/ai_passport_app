import SwiftUI

/// Luxurious SUMUS™ splash screen.
struct SplashSumusView: View {
    @State private var isVisible = false

    private let backgroundColor = Color(red: 255/255, green: 255/255, blue: 255/255)
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
                        Image("sumus_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: logoSize, height: logoSize)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

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

#Preview {
    SplashSumusView()
        .frame(width: 390, height: 844)
}
