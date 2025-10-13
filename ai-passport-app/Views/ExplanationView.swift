// Views/ExplanationView.swift
import SwiftUI

/// 解説画面
struct ExplanationView: View {
    let quiz: Quiz
    let selectedAnswerIndex: Int
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // 正誤判定
            HStack {
                Text(selectedAnswerIndex == quiz.answerIndex ? "正解 ✅" : "不正解 ❌")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(selectedAnswerIndex == quiz.answerIndex ? Color.orange : Color.red)
                    .cornerRadius(8)
                Spacer()
            }

            // 問題文
            VStack(alignment: .leading, spacing: 8) {
                Text(quiz.question)
                    .font(.title3)
                    .fontWeight(.bold)

                // 選択肢一覧（正解にマーク）
                ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                    HStack {
                        Text(choice)
                            .foregroundColor(index == quiz.answerIndex ? .orange : .primary)
                        if index == quiz.answerIndex {
                            Text("← 正解")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            // 解説
            ScrollView {
                Text(quiz.explanation ?? "解説はありません。")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
            .frame(maxHeight: 200)

            Spacer()

            // 次の問題へ
            Button(action: onNext) {
                Text("次の問題へ")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(12)
            }
        }
        .padding()
        .navigationTitle("解説")
        .navigationBarTitleDisplayMode(.inline)
    }
}
