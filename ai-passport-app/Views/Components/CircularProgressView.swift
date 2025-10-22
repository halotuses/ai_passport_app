import SwiftUI

/// ホーム画面で全体の学習状況を示す円形プログレスビュー
struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 12
    var size: CGFloat = 140

    private var shouldDisplayPlaceholder: Bool {
        progress.isNaN || progress < 0
    }
    

    private var clampedProgress: Double {
        guard !shouldDisplayPlaceholder else { return 0 }
        return min(max(progress, 0), 1)
    }

    private var progressText: String {
        guard !shouldDisplayPlaceholder else { return "--%" }
        return "\(Int((clampedProgress * 100).rounded()))%"
    }

    private var gradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color.themeMain,
                Color.themeSecondary,
                Color.themeQuaternary
            ]),
            center: .center
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeSurfaceElevated.opacity(0.4), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: clampedProgress)
                .opacity(shouldDisplayPlaceholder ? 0.35 : 1)

            Text(progressText)
                .font(.system(size: size * 0.2, weight: .bold))
                .foregroundColor(.themeTextPrimary)
        }
        .frame(width: size, height: size)
        .padding(lineWidth / 2)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.6), radius: 12, x: 0, y: 8)
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            CircularProgressView(progress: 0.68)
            CircularProgressView(progress: -1)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
