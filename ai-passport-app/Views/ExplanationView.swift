import SwiftUI
import AVFoundation

/// 解説画面（問題の正誤と解説を表示）
struct ExplanationView: View {
    @ObservedObject var viewModel: QuizViewModel
    let quiz: Quiz
    let selectedAnswerIndex: Int
    @Environment(\.dismiss) private var dismiss
    let onNext: () -> Void
    
    private var isAnswerCorrect: Bool {
        selectedAnswerIndex == quiz.answerIndex
    }

    private var hasNextQuestion: Bool {
        viewModel.hasNextQuestion
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let isBookmarked = viewModel.isBookmarked(quiz: quiz)
                HStack {
                    Spacer()
                    Button {
                        viewModel.toggleBookmark(for: quiz)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? .yellow : .gray)
                    }
                    .accessibilityLabel("ブックマーク")
                }
                
                // MARK: - 正誤表示
                HStack {
                    let isCorrect = selectedAnswerIndex == quiz.answerIndex
                    Text(isCorrect ? "正解 ✅" : "不正解 ❌")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(isCorrect ? Color.themeCorrect : Color.themeIncorrect)
                        .cornerRadius(8)
                    Spacer()
                }
                
                // MARK: - 問題文
                Text(quiz.question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 4)
                    .foregroundColor(.themeTextPrimary)
                
                // MARK: - 選択肢と正解表示
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                        choiceRow(for: choice,
                                  isCorrectChoice: index == quiz.answerIndex,
                                  isSelectedChoice: index == selectedAnswerIndex,
                                  isAnswerCorrect: isAnswerCorrect)
                    }
                }
                .padding(.vertical, 4)
                
                Divider()
                
                // MARK: - 解説文
                if let explanationText {
                    Text(explanationText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.themeTextPrimary)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                            .imageScale(.large)

                        Text("解説データが見つかりません。")
                            .font(.body)
                            .foregroundColor(.themeTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                }
                
                Spacer(minLength: 80) // 下のボタン分の余白
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.themeBase, Color.themeSurfaceAlt.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )

        // ✅ 常に画面下部にボタンを固定
        .safeAreaInset(edge: .bottom) {
            Button(action: {
                handleNextAction()
            }) {
                Text(hasNextQuestion ? "次の問題へ" : "結果表示")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.themeSecondary, Color.themeMain],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.themeSecondary.opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}


private extension ExplanationView {
    var explanationText: String? {
        guard let text = quiz.explanation?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }
        return text
    }
    enum ChoiceTagType: String {
        case correct = "正解"
        case selected = "回答"
    }

    @ViewBuilder
    func choiceRow(for text: String,
                   isCorrectChoice: Bool,
                   isSelectedChoice: Bool,
                   isAnswerCorrect: Bool) -> some View {
        let tags = choiceTags(isCorrectChoice: isCorrectChoice, isSelectedChoice: isSelectedChoice)
        let highlightColor = choiceHighlightColor(isCorrectChoice: isCorrectChoice,
                                                  isSelectedChoice: isSelectedChoice,
                                                  isAnswerCorrect: isAnswerCorrect)

        HStack(alignment: .center, spacing: 12) {
            Text(text)
                .foregroundColor(.themeTextPrimary)

            Spacer(minLength: 8)

            ForEach(tags, id: \.self) { tag in
                tagView(for: tag, isAnswerCorrect: isAnswerCorrect)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(highlightColor ?? Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(highlightColor ?? Color.themeMain.opacity(0.08), lineWidth: highlightColor == nil ? 1 : 1.5)
        )
        .shadow(color: Color.themeShadowSoft.opacity(highlightColor == nil ? 0.6 : 1), radius: 8, x: 0, y: 4)
    }

    func choiceTags(isCorrectChoice: Bool, isSelectedChoice: Bool) -> [ChoiceTagType] {
        var tags: [ChoiceTagType] = []
        if isCorrectChoice { tags.append(.correct) }
        if isSelectedChoice { tags.append(.selected) }
        return tags
    }

    func choiceHighlightColor(isCorrectChoice: Bool,
                              isSelectedChoice: Bool,
                              isAnswerCorrect: Bool) -> Color? {
        if isAnswerCorrect {
            return isCorrectChoice ? Color.themeCorrect.opacity(0.22) : nil
        }
        
        if isCorrectChoice {
            return Color.themeCorrect.opacity(0.22)
        }

        if isSelectedChoice {
            return Color.themeIncorrect.opacity(0.18)
        }

        return nil
    }

    @ViewBuilder
    func tagView(for type: ChoiceTagType, isAnswerCorrect: Bool) -> some View {
        let color = tagColor(for: type, isAnswerCorrect: isAnswerCorrect)

        Text(type.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color)
            )
    }

    func tagColor(for type: ChoiceTagType, isAnswerCorrect: Bool) -> Color {
        switch type {
        case .correct:
            return Color.themeCorrect
        case .selected:
            return isAnswerCorrect ? Color.themeCorrect : Color.themeIncorrect
        }
    }
    func handleNextAction() {
        if hasNextQuestion {
            viewModel.moveNext()
        } else {
            viewModel.finishQuiz()
        }

        onNext()
    }
}
