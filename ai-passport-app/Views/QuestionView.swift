import SwiftUI

/// 問題文＋選択肢表示部（縦スリム＋選択肢直前余白追加版）
struct QuestionView: View {

    let question: String?
    let choices: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                if let question = question {
                    Text(question)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                }

                // ここに余白を追加
                Spacer().frame(height: 12)

                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    HStack(spacing: 8) {
                        Text(label(for: index))
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(width: 32, height: 32)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(16)

                        Text(choice)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(8)
                    .background(Color(white: 0.95))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(maxHeight: .infinity)
    }

    private func label(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ"]
        return index < labels.count ? labels[index] : "？"
    }
}
