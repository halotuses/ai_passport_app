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

                    VStack(spacing: 12) {
                        ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choiceText in
                            HStack(alignment: .top, spacing: 14) {
                                Text(choiceLabel(for: index))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.themePillBackground)
                                    .foregroundColor(.themeTextSecondary)
                                    .clipShape(Capsule())

                                Text(choiceText)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.themeTextPrimary)
                                Spacer(minLength: 8)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.themeMain.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 6)
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
