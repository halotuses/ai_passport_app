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
                        .foregroundColor(.themeTextPrimary)

                    VStack(spacing: 10) {
                        ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choiceText in
                            HStack(alignment: .center, spacing: 12) {
                                Text(choiceLabel(for: index))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(
                                                LinearGradient(colors: [Color.themeMain, Color.themeAccent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                            )
                                    )

                                Text(choiceText)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.themeTextPrimary)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.themeSurfaceElevated)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
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
