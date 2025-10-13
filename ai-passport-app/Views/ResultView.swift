import SwiftUI

struct ResultView: View {
    let correctCount: Int
    let totalCount: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            Text("学習アプリ")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.8, green: 1.0, blue: 0.8))

            Spacer()

            // ✅ 「第◯問」の表示を削除
            // 結果メッセージのみ表示
            Text(resultMessage)
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.bottom, 8)

            // 結果詳細
            Text("正解数：\(correctCount) / \(totalCount)")
                .font(.body)
            Text("正答率：\(Int(Double(correctCount) / Double(totalCount) * 100))%")
                .font(.body)

            // トップに戻るボタン
            Button(action: onRestart) {
                Text("トップに戻る")
                    .fontWeight(.medium)
                    .padding()
                    .frame(width: 220)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.top, 20)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }

    private var resultMessage: String {
        let rate = Double(correctCount) / Double(totalCount)
        switch rate {
        case 1.0:
            return "完璧です！"
        case 0.7...:
            return "よくできました！"
        case 0.4...:
            return "あと少し！"
        default:
            return "もう一度チャレンジ！"
        }
    }
}
