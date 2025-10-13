import SwiftUI

struct QuestionView: View {
    // ✅ QuizViewModelを監視するObservableObjectとして受け取る
    @ObservedObject var viewModel: QuizViewModel

    var body: some View {
        VStack(spacing: 20) {

            // MARK: - 問題ヘッダー
            if let quiz = viewModel.currentQuiz {
                Text("第\(viewModel.currentQuestionIndex + 1)問")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                Text(quiz.question)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
            }

            // MARK: - 選択肢リスト
            if let quiz = viewModel.currentQuiz {
                let choices = quiz.choices
                VStack(spacing: 10) {
                    ForEach(Array(choices.enumerated()), id: \.offset) { index, choiceText in
                        Button(action: {
                            // ✅ 選択肢が押されたときにviewModelのメソッドを呼び出す
                            viewModel.selectAnswer(index: index)
                        }) {
                            HStack {
                                Text(choiceText)
                                    .font(.body)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                // ✅ 選択中の選択肢を青く表示
                                viewModel.selectedAnswerIndex == index
                                    ? Color.blue.opacity(0.3)
                                    : Color.gray.opacity(0.1)
                            )
                            .cornerRadius(10)
                        }
                        // ✅ 回答後は選択できないようにする
                        .disabled(viewModel.isSubmitted)
                    }
                }
                .padding(.horizontal)
            }

            // MARK: - ボタン群
            VStack(spacing: 15) {
                Button(action: {
                    viewModel.submitAnswer()
                }) {
                    Text("解答する")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSubmitted)
            }
        }
    }
}
