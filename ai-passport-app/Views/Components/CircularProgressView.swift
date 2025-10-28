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

            ZStack {
                // 背景の薄い灰色リング（全体のガイド）
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: ringWidth)

                // 各進捗セグメントの描画範囲を計算
                let redEnd = animatedHighlight       // 赤（ハイライト）の終了位置
                let greenStart = redEnd              // 緑の開始位置
                let greenEnd = animatedTotal         // 緑の終了位置
                let greyStart = greenEnd             // グレーの開始位置
                let greyEnd = 1.0                    // グレーの終了位置（円全体）

                // 赤いセグメント（ハイライト部分）
                if redEnd > 0 {
                    segment(
                        start: 0,
                        end: redEnd,
                        color: .red,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedHighlight)
                }

                // 緑のセグメント（ハイライト以外の進捗部分）
                if greenEnd > greenStart {
                    segment(
                        start: greenStart,
                        end: greenEnd,
                        color: .green,
                        ringWidth: ringWidth
                    )
                    .animation(.easeOut(duration: 0.6), value: animatedTotal)
                }

                // グレーのセグメント（未達成部分）
                if greyEnd > greyStart {
                    segment(
                        start: greyStart,
                        end: greyEnd,
                        color: .gray,
                        ringWidth: ringWidth
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

    // 円弧（セグメント）を描画する共通処理
    private func segment(
        start: Double,    // 開始位置（0〜1）
        end: Double,      // 終了位置（0〜1）
        color: Color,     // セグメントの色
        ringWidth: CGFloat // 線の太さ
    ) -> some View {
        Circle()
            // trimで円の一部だけを描画
            .trim(from: start, to: end)
            // 線のスタイルを指定
            .stroke(
                color,
                style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
            )
            // 円の開始位置を上（12時）にする
            .rotationEffect(.degrees(-90))
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
