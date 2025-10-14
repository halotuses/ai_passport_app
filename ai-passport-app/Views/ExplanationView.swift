import SwiftUI

/// 解説画面（問題の正誤と解説を表示）
struct ExplanationView: View {
    let quiz: Quiz
    let selectedAnswerIndex: Int
    let hasNextQuestion: Bool
    let onNextQuestion: () -> Void
    let onShowResult: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject private var mainViewState: MainViewState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: - 正誤表示
                HStack {
                    Text(selectedAnswerIndex == quiz.answerIndex ? "正解 ✅" : "不正解 ❌")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(selectedAnswerIndex == quiz.answerIndex ? Color.orange : Color.red)
                        .cornerRadius(8)
                    Spacer()
                }
                
                // MARK: - 問題文
                Text(quiz.question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 4)
                
                // MARK: - 選択肢と正解表示
                VStack(alignment: .leading, spacing: 6) {
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
                .padding(.vertical, 4)
                
                Divider()
                
                // MARK: - 解説文
                Text(quiz.explanation ?? "解説はありません。")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 80) // 下のボタン分の余白
            }
            .padding()
        }

        .onChange(of: mainViewState.navigationResetToken) { _ in
            onDismiss()
        }

        // ✅ 常に画面下部にボタンを固定
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                if hasNextQuestion {
                    onNextQuestion()
                } else {
                    onShowResult()
                }
            }) {
                Text(hasNextQuestion ? "次の問題へ" : "結果表示")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}
