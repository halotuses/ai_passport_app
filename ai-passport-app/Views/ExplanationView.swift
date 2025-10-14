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
    
    private var isAnswerCorrect: Bool {
        selectedAnswerIndex == quiz.answerIndex
    }

    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
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
                Text(quiz.explanation ?? "解説はありません。")
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.themeTextPrimary)
                
                Spacer(minLength: 80) // 下のボタン分の余白
            }
            .padding()
        }
        .background(Color.themeBase)
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
                    .background(Color.themeMain)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.themeMainHover.opacity(0.3), radius: 12, x: 0, y: 6)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}


private extension ExplanationView {
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
                .stroke(highlightColor ?? Color.clear, lineWidth: highlightColor == nil ? 0 : 1.5)
        )
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
}
