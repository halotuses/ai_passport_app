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
                Circle()
                
                    .trim(from: 0, to: animatedTotal)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)

                Circle()
                    .trim(
                        from: max(0, animatedTotal - animatedHighlight),
                        to: animatedTotal
                    )
                    .stroke(
                        Color.red,
                        style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: animatedHighlight)

                Text(percentageText)
                    .font(.system(size: diameter * 0.25, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .animation(.easeOut(duration: 0.6), value: percentageText)
            }
            .frame(width: diameter, height: diameter)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedTotal = sanitizedTotal
                    animatedHighlight = sanitizedHighlight
                }
            }
            .onChange(of: totalProgress) { _ in
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedTotal = sanitizedTotal
                    animatedHighlight = sanitizedHighlight
                }
            }
            .onChange(of: highlightProgress) { _ in
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedTotal = sanitizedTotal
                    animatedHighlight = sanitizedHighlight
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
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
