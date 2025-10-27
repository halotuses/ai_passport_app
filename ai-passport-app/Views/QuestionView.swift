import SwiftUI

struct QuestionView: View {
    // ✅ QuizViewModelを監視するObservableObjectとして受け取る
    @ObservedObject var viewModel: QuizViewModel
    @State private var handledQuestionIndex: Int?
    var body: some View {
        VStack(spacing: 20) {
            

            if let quiz = viewModel.currentQuiz {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Spacer()
                        BookmarkToggleButton(viewModel: viewModel, quiz: quiz)
                    }
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
        .onChange(of: viewModel.selectedAnswerIndex) { newValue in
            guard let selectedIndex = newValue,
                  handledQuestionIndex != viewModel.currentQuestionIndex,
                  let quiz = viewModel.currentQuiz else { return }

            handledQuestionIndex = viewModel.currentQuestionIndex
            let sound: SoundManager.SoundType = (selectedIndex == quiz.answerIndex) ? .correct : .wrong
            SoundManager.shared.play(sound)
        }
        .onChange(of: viewModel.currentQuestionIndex) { _ in
            handledQuestionIndex = nil
        }
    }
    
    private func choiceLabel(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ"]
        return index < labels.count ? labels[index] : "?"
    }
}

struct BookmarkToggleButton: View {
    @ObservedObject var viewModel: QuizViewModel
    let quiz: Quiz

    var body: some View {
        let isBookmarked = viewModel.isBookmarked(quiz: quiz)
        Button {
            viewModel.toggleBookmark(for: quiz)
        } label: {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(isBookmarked ? .yellow : .gray)
        }
        .accessibilityLabel("ブックマーク")
        .accessibilityAddTraits(isBookmarked ? .isSelected : [])
    }
}
