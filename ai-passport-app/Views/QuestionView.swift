import SwiftUI


struct QuestionView: View {
    // ✅ QuizViewModelを監視するObservableObjectとして受け取る
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            

            if let quiz = viewModel.currentQuiz {
                VStack(alignment: .leading, spacing: 16) {
                    Text(quiz.question)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)

                    VStack(spacing: 10) {
                        ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choiceText in
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
