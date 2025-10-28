import SwiftUI

struct CircularProgressView: View {
    var totalProgress: Double
    var highlightProgress: Double
    var percentageText: String

    @State private var animatedTotal: Double = 0
    @State private var animatedHighlight: Double = 0

    private func clampedProgress(_ value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        return min(max(value, 0), 1)
    }

    private var sanitizedTotal: Double {
        clampedProgress(totalProgress)
    }

    private var sanitizedHighlight: Double {
        min(clampedProgress(highlightProgress), sanitizedTotal)
    }

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let ringWidth = diameter * 0.12
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: ringWidth)
                let redEnd = animatedHighlight
                let greenStart = redEnd
                let greenEnd = animatedTotal
                let greyStart = greenEnd
                let greyEnd = 1.0

                if redEnd > 0 {
                    segment(
                        start: 0,
                        end: redEnd,
                        color: .red,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedHighlight)
                }

                if greenEnd > greenStart {
                    segment(
                        start: greenStart,
                        end: greenEnd,
                        color: .green,
                        ringWidth: ringWidth
                    )
                    
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }
                
                if greyEnd > greyStart {
                    segment(
                        start: greyStart,
                        end: greyEnd,
                        color: .gray,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                if redEnd > 0 {
                    capView(
                        for: redEnd,
                        color: .red,
                        diameter: diameter,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedHighlight)
                }

                if greenEnd > greenStart {
                    capView(
                        for: greenEnd,
                        color: .green,
                        diameter: diameter,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                if greyEnd > greyStart {
                    capView(
                        for: greyEnd,
                        color: .gray,
                        diameter: diameter,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                Text(percentageText)
                    .font(.system(size: diameter * 0.25, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .animation(.easeOut(duration: 0.6), value: percentageText)
            }
            .frame(width: diameter, height: diameter)
            .onAppear(perform: animateProgress)
            .onChange(of: totalProgress) { _ in animateProgress() }
            .onChange(of: highlightProgress) { _ in animateProgress() }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

extension CircularProgressView {
    private func animateProgress() {
        withAnimation(.easeOut(duration: 0.6)) {
            animatedTotal = sanitizedTotal
            animatedHighlight = sanitizedHighlight
        }
    }

    private func segment(
        start: Double,
        end: Double,
        color: Color,
        ringWidth: CGFloat
    ) -> some View {
        Circle()
            .trim(from: start, to: end)
            .stroke(
                color,
                style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
            )
            .rotationEffect(.degrees(-90))
    }

    private func capOffset(
        for progress: Double,
        diameter: CGFloat,
        ringWidth: CGFloat
    ) -> CGSize {
        let normalizedProgress = clampedProgress(progress).truncatingRemainder(dividingBy: 1)
        let angle = (normalizedProgress * 2 * .pi) - (.pi / 2)
        let radius = max((diameter - ringWidth) / 2, 0)
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }

    private func capView(
        for progress: Double,
        color: Color,
        diameter: CGFloat,
        ringWidth: CGFloat
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: ringWidth, height: ringWidth)
            .offset(capOffset(for: progress, diameter: diameter, ringWidth: ringWidth))
    }
}

struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            CircularProgressView(
                totalProgress: 0.25,
                highlightProgress: 0.05,
                percentageText: "25%"
            )
            .frame(width: 160, height: 160)
            CircularProgressView(
                
                totalProgress: 0.75,
                highlightProgress: 0.15,
                percentageText: "75%"
            )
            .frame(width: 160, height: 160)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
