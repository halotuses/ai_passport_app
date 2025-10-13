import SwiftUI

/// 解説画面（問題の正誤と解説を表示）
struct ExplanationView: View {
    let quiz: Quiz
    let selectedAnswerIndex: Int
    let hasNextQuestion: Bool
    let onNextQuestion: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject private var mainViewState: MainViewState
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // MARK: 正誤
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
                
                // MARK: 問題文
                Text(quiz.question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 4)
                
                // MARK: 選択肢と正解表示
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
                
                // MARK: 解説文
                Text(quiz.explanation ?? "解説はありません。")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 24)
                
                // MARK: 次の問題へ
                Button(action: {
                    onNextQuestion()
                    onDismiss()
                    
                }) {
                    
                    Text(hasNextQuestion ? "次の問題へ" : "結果表示")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("解説")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mainViewState.navigationResetToken) { _ in
            onDismiss()
        }
        
    }
}
