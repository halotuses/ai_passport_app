import SwiftUI

struct ResultView: View {
    let correctCount: Int
    let totalCount: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 20) {

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
        .padding(.top, 20)
        .navigationBarBackButtonHidden(true)
        .navigationTitle("結果")
        .navigationBarTitleDisplayMode(.inline)
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
