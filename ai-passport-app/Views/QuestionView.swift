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

                        HStack(spacing: 12) {
                            Text(choiceLabel(for: index))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)

                            Text(choiceText)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                            Spacer()
                         }

                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                     }
                 }
                 .padding(.horizontal)
             }
 
 
         }
     }

    private func choiceLabel(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ"]
        return index < labels.count ? labels[index] : "?"
    }
 }
