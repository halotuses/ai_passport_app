import SwiftUI

// 円形プログレスバーを描画するカスタムView
struct CircularProgressView: View {
    // 全体の進捗割合（0〜1）
    var totalProgress: Double
    // ハイライト部分（例：正解数など）の進捗割合（0〜1）
    var highlightProgress: Double
    // 中央に表示するパーセンテージテキスト（例："75%"）
    var percentageText: String

    // アニメーション制御用の状態変数
    @State private var animatedTotal: Double = 0
    @State private var animatedHighlight: Double = 0

    // 値を0〜1の範囲に制限し、NaNの場合は0を返す
    private func clampedProgress(_ value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        return min(max(value, 0), 1)
    }

    // totalProgress の正規化（0〜1に制限）
    private var sanitizedTotal: Double {
        clampedProgress(totalProgress)
    }

    // highlightProgress の正規化（totalProgressを超えないよう制限）
    private var sanitizedHighlight: Double {
        min(clampedProgress(highlightProgress), sanitizedTotal)
    }

    var body: some View {
        GeometryReader { geometry in
            // コンテナ内の最小辺を円の直径として使用
            let diameter = min(geometry.size.width, geometry.size.height)
            // リングの線幅を直径の12%に設定
            let ringWidth = diameter * 0.12
            let radius = diameter / 2

            ZStack {
                // ⚪️ 背景の薄い灰色リング（全体のガイド）
                Path { path in
                    path.addArc(center: CGPoint(x: radius, y: radius),
                                radius: radius - ringWidth / 2,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360),
                                clockwise: false)
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: ringWidth)

                // 各進捗セグメントの角度を算出
                let redEnd = animatedHighlight       // 赤（ハイライト）の終了割合
                let greenStart = redEnd              // 緑の開始割合
                let greenEnd = animatedTotal         // 緑の終了割合

                // 🔴 赤いセグメント（ハイライト部分）
                if redEnd > 0 {
                    segmentArc(
                        start: 0,
                        end: redEnd,
                        color: .red,
                        ringWidth: ringWidth,
                        diameter: diameter
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedHighlight)
                }

                // 🟢 緑のセグメント（ハイライト以外の進捗部分）
                if greenEnd > greenStart {
                    segmentArc(
                        start: greenStart,
                        end: greenEnd,
                        color: .green,
                        ringWidth: ringWidth,
                        diameter: diameter
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                // ⚪️ グレーのセグメント（未達成部分）
                if greenEnd < 1.0 {
                    segmentArc(
                        start: greenEnd,
                        end: 1.0,
                        color: .gray,
                        ringWidth: ringWidth,
                        diameter: diameter
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                // 中央のテキスト（進捗率を表示）
                Text(percentageText)
                    .font(.system(size: diameter * 0.25, weight: .bold))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .animation(.easeOut(duration: 0.6), value: percentageText)
            }
            // 全体のサイズを円に合わせる
            .frame(width: diameter, height: diameter)
            // 初回表示時にアニメーション開始
            .onAppear(perform: animateProgress)
            // totalProgressの変化時に再アニメーション
            .onChange(of: totalProgress) { _ in animateProgress() }
            // highlightProgressの変化時にも再アニメーション
            .onChange(of: highlightProgress) { _ in animateProgress() }
        }
        // アスペクト比を1:1に固定（円を維持）
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Extension for helper methods
extension CircularProgressView {
    // アニメーション付きで進捗値を更新
    private func animateProgress() {
        withAnimation(.easeOut(duration: 0.6)) {
            animatedTotal = sanitizedTotal
            animatedHighlight = sanitizedHighlight
        }
    }

    // Pathベースの円弧セグメント描画（ブレンド完全排除版）
    private func segmentArc(
        start: Double,
        end: Double,
        color: Color,
        ringWidth: CGFloat,
        diameter: CGFloat
    ) -> some View {
        let radius = diameter / 2
        return Path { path in
            let startAngle = Angle(degrees: -90 + 360 * start)
            let endAngle = Angle(degrees: -90 + 360 * end)
            path.addArc(center: CGPoint(x: radius, y: radius),
                        radius: radius - ringWidth / 2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
        }
        .stroke(
            color,
            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
        )
    }
}

// MARK: - プレビュー設定
struct CircularProgressView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            // プレビュー1：25%進捗、ハイライト5%
            CircularProgressView(
                totalProgress: 0.25,
                highlightProgress: 0.05,
                percentageText: "25%"
            )
            .frame(width: 160, height: 160)

            // プレビュー2：75%進捗、ハイライト15%
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
