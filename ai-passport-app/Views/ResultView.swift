import SwiftUI

struct ResultView: View {
    let correctCount: Int
    let totalCount: Int
    let onRestart: () -> Void
    let onBackToChapterSelection: () -> Void
    let onBackToUnitSelection: () -> Void
    let onImmediatePersist: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.themeBase, Color.themeMain.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 16)

                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [resultIconColor.opacity(0.35), resultIconColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 20
                            )
                            .frame(width: 160, height: 160)

                        Circle()
                            .fill(Color.themeSurface)
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.themeMain.opacity(0.02), radius: 12, x: 0, y: 10)

                        resultIconView
                    }

                    VStack(spacing: 16) {
                        Text(resultMessage)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.themeTextPrimary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 8) {
                            Text("正解数")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.themeTextSecondary)
                            Text("\(correctCount) / \(totalCount)")
                                .font(.title2)
                                .fontWeight(.semibold)

                                .foregroundColor(.themeTextPrimary)

                        }
                        VStack(spacing: 12) {
                            HStack {
                                Text("正答率")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.themeTextSecondary)
                                Spacer()
                                Text("\(accuracyPercentage)%")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(resultIconColor)
                            }

                            ResultProgressBar(
                                value: accuracy,
                                fill: progressBarFillStyle,
                                trackColor: progressBarTrackColor
                            )
                            .frame(height: 8)

                        }
                    }

                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.themeSurface)
                            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 12)
                    )
                    .padding(.horizontal)

                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Button(action: {
                                SoundManager.shared.play(.tap)
                                onBackToUnitSelection()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.headline)
                                    Text("単元選択に戻る")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [Color.themeMain, Color.themeAccent], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .shadow(color: Color.themeMainHover.opacity(0.3), radius: 16, x: 0, y: 10)

                            Button(action: {
                                SoundManager.shared.play(.tap)
                                onBackToChapterSelection()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.headline)
                                    Text("章選択に戻る")
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(colors: [Color.themeMain, Color.themeAccent], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                            }
                            .shadow(color: Color.themeMainHover.opacity(0.3), radius: 16, x: 0, y: 10)
                        }

                        Button(action: {
                            SoundManager.shared.play(.tap)
                            onRestart()
                        }) {
                            HStack {
                                Image(systemName: "repeat")
                                    .font(.headline)
                                Text("もう一回")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }

                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(colors: [Color.themeMain, Color.themeAccent], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }

                        .shadow(color: Color.themeMainHover.opacity(0.3), radius: 16, x: 0, y: 10)

                        Text(encouragementMessage)
                            .font(.footnote)
                            .foregroundColor(.themeTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }

        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // 即時反映対応: 結果画面表示と同時に永続化を完了させる
            onImmediatePersist()
        }
    }

    private var resultMessage: String {
        let rate = Double(correctCount) / Double(totalCount)
        let messages: [String]

        switch rate {
        case 1.0:
            messages = [
                "完璧です！",
                "すごい！全問正解！",
                "圧倒的ですね！",
                "非の打ち所がありません！",
                "まさに理想的な結果です！",
                "最高のパフォーマンス！",
                "素晴らしい集中力！",
                "完璧な理解度です！",
                "お見事！文句なし！",
                "これ以上ない結果です！"
            ]
        case 0.8...:
            messages = [
                "よくできました！",
                "あと少しで満点です！",
                "とても良い結果ですね！",
                "この調子でいきましょう！",
                "かなりの実力です！",
                "しっかり理解できています！",
                "安定した出来栄え！",
                "惜しい！もう少しで完璧！",
                "とても良い手応えです！",
                "一歩ずつ確実に成長しています！"
            ]
        case 0.6...:
            messages = [
                "あと少し！",
                "いい線いってます！",
                "少しの復習で完璧になります！",
                "惜しいところまで来ています！",
                "基礎はつかめていますね！",
                "次はもっといけます！",
                "間違いもチャンスです！",
                "理解が進んできています！",
                "良いペースです！",
                "次回は満点を狙いましょう！"
            ]
        default:
            messages = [
                "もう一度チャレンジ！",
                "ここからがスタート！",
                "少しずつ慣れていきましょう！",
                "焦らず取り組めば大丈夫！",
                "失敗は成功のもと！",
                "何度でも挑戦できます！",
                "大切なのは続けること！",
                "きっと次はもっと良くなります！",
                "まずは一歩ずつ！",
                "一緒に頑張っていきましょう！"
            ]
        }

        return messages.randomElement() ?? "頑張りました！"
    }

    
    private var encouragementMessage: String {
        let rate = accuracy
        let messages: [String]

        switch rate {
        case 1.0:
            messages = [
                "次のチャレンジもこの調子で頑張りましょう！",
                "完璧です！自信を持って次へ進みましょう！",
                "努力が実を結びましたね！",
                "この勢いでどんどん先に進みましょう！",
                "素晴らしい成果です！",
                "知識が確実に定着しています！",
                "積み重ねが力になっています！",
                "この調子ならどんな問題も怖くない！",
                "最高のスタートです！",
                "まさに理想的な学び方です！"
            ]
        case 0.8...:
            messages = [
                "あと少しで満点です。復習してさらにレベルアップ！",
                "高い正答率！素晴らしいですね！",
                "もう一歩で完璧です！",
                "このペースを保ちましょう！",
                "実力がしっかりついています！",
                "惜しい！でも確実に成長しています！",
                "安定感がありますね！",
                "苦手な部分を復習してさらに伸ばしましょう！",
                "次こそ満点を狙いましょう！",
                "とても良い学習サイクルです！"
            ]
        case 0.6...:
            messages = [
                "苦手な部分を振り返って、次回の正解率アップを目指しましょう。",
                "ここからの伸びが大事です！",
                "理解度が上がってきていますね！",
                "もう少し復習すれば完璧です！",
                "次はもっとできるはず！",
                "少しずつ確実に上達しています！",
                "反復が大切です！",
                "前回より進歩しています！",
                "地道な努力が実を結びます！",
                "小さな積み重ねが大きな成果に！"
            ]
        default:
            messages = [
                "焦らずに、解説を見ながら理解を深めていきましょう。",
                "ここからが本番です！",
                "失敗は学びのチャンス！",
                "今は理解を固める時間です！",
                "ゆっくり進めば大丈夫！",
                "最初の一歩を踏み出しましたね！",
                "何度でも挑戦すれば上達します！",
                "小さな成功を積み重ねましょう！",
                "大丈夫、次はもっと良くなります！",
                "繰り返すことで必ず上達します！"
            ]
        }

        return messages.randomElement() ?? "次も頑張りましょう！"
    }

    private var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    private var accuracyPercentage: Int {
        Int((accuracy * 100).rounded())
    }

    private var resultIconName: String {
        let rate = accuracy
        switch rate {
        case 1.0:
            return "crown.fill"
        case 0.8...:
            return "star.fill"
        case 0.6...:
            return "flame.fill"
        default:
            return "leaf.fill"
        }
    }
    
    private var resultIconColor: Color {
        let rate = accuracy
        switch rate {
        case 1.0:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 0.8...:
            return .yellow
        case 0.6...:
            return .red
        default:
            return .themeAccent
        }
    }
    
    @ViewBuilder
    private var resultIconView: some View {
        if let gradient = resultIconGradient {
            gradient
                .mask(
                    Image(systemName: resultIconName)
                        .resizable()
                        .scaledToFit()
                )
                .frame(width: 80, height: 80)
        } else {
            Image(systemName: resultIconName)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(resultIconColor)
        }
    }

    private var resultIconGradient: LinearGradient? {
        guard resultIconName == "crown.fill" else { return nil }
        return .crownGold
    }

    private var progressBarFillStyle: AnyShapeStyle {
        if let gradient = resultIconGradient {
            return AnyShapeStyle(gradient)
        } else {
            return AnyShapeStyle(resultIconColor)
        }
    }

    private var progressBarTrackColor: Color {
        resultIconColor.opacity(0.2)
    }

}

private struct ResultProgressBar: View {
    var value: Double
    var fill: AnyShapeStyle
    var trackColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(trackColor)

                Capsule()
                    .fill(fill)
                    .frame(width: barWidth(for: geometry.size.width))
            }
        }
    }

    private func barWidth(for totalWidth: CGFloat) -> CGFloat {
        let clampedValue = max(0, min(1, value))
        return totalWidth * CGFloat(clampedValue)
    }
}
