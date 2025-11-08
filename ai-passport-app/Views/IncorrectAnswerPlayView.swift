import SwiftUI

struct IncorrectAnswerPlayView: View {
    struct ExplanationRoute: Identifiable {
        let id = UUID()
        let quiz: Quiz
        let selectedAnswerIndex: Int
    }

    let unit: IncorrectAnswerView.UnitEntry
    let chapter: IncorrectAnswerView.ChapterEntry
    let onClose: () -> Void

    @StateObject private var viewModel: IncorrectAnswerPlayViewModel
    @State private var activeExplanationRoute: ExplanationRoute?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewState: MainViewState

    init(
        unit: IncorrectAnswerView.UnitEntry,
        chapter: IncorrectAnswerView.ChapterEntry,
        initialQuestionId: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.chapter = chapter
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: IncorrectAnswerPlayViewModel(
                chapter: chapter,
                initialQuestionId: initialQuestionId
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let route = activeExplanationRoute {
                IncorrectAnswerExplanationView(
                    viewModel: viewModel,
                    quiz: route.quiz,
                    selectedAnswerIndex: route.selectedAnswerIndex,
                    onNext: handleExplanationNext
                )
            } else {
                contentBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase)
        .onAppear(perform: handleOnAppear)
        .onChange(of: viewModel.currentQuestionIndex) { _ in updateHeader() }
        .onChange(of: viewModel.quizzes.count) { _ in updateHeader() }
        .onDisappear(perform: handleOnDisappear)
    }
}

private extension IncorrectAnswerPlayView {
    @ViewBuilder
    var contentBody: some View {
        if viewModel.isLoading {
            ProgressView("読み込み中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.hasError || viewModel.totalCount == 0 {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.themeIncorrect)
                Text("復習できる問題が見つかりませんでした。")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
                Button("一覧に戻る") {
                    finishReview()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.themeButtonSecondary)
                .foregroundColor(.themeTextPrimary)
                .cornerRadius(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            VStack(spacing: 0) {
                IncorrectAnswerQuestionView(viewModel: viewModel)
                    .padding(.top, 12)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.themeMain.opacity(0.2))
                        .padding(.top, 12)
                    AnswerAreaView(
                        choices: viewModel.currentQuiz?.choices ?? [],
                        selectAction: handleAnswerSelection
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 0)
                }
                .background(Color.themeBase)
            }
        }
    }

    func handleOnAppear() {
        viewModel.loadIfNeeded()
        updateHeader()
    }

    func handleOnDisappear() {
        mainViewState.clearHeaderBookmark()
    }

    func handleAnswerSelection(_ index: Int) {
        guard let quiz = viewModel.currentQuiz else { return }
        viewModel.selectAnswer(index)
        activeExplanationRoute = ExplanationRoute(quiz: quiz, selectedAnswerIndex: index)
    }

    func handleExplanationNext() {
        let hasNext = viewModel.advanceToNextQuestion()
        activeExplanationRoute = nil
        if hasNext {
            updateHeader()
        } else {
            finishReview()
        }
    }

    func finishReview() {
        dismiss()
        onClose()
    }

    func updateHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            finishReview()
        }

        let baseTitle = "不正解復習（\(unit.unit.title)・\(chapter.chapter.title)）"

        if let _ = activeExplanationRoute, viewModel.totalCount > 0 {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            let title = "\(baseTitle) 第\(questionNumber)問 解説"
            mainViewState.setHeader(title: title, backButton: backButton)
        } else if viewModel.totalCount > 0 {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            let title = "\(baseTitle) 第\(questionNumber)問"
            mainViewState.setHeader(title: title, backButton: backButton)
        } else {
            mainViewState.setHeader(title: baseTitle, backButton: backButton)
        }
    }
}

private struct IncorrectAnswerQuestionView: View {
    @ObservedObject var viewModel: IncorrectAnswerPlayViewModel
    @State private var handledQuestionIndex: Int?

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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func choiceLabel(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ"]
        return index < labels.count ? labels[index] : "?"
    }
}

private struct IncorrectAnswerExplanationView: View {
    @ObservedObject var viewModel: IncorrectAnswerPlayViewModel
    let quiz: Quiz
    let selectedAnswerIndex: Int
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
                HStack {
                    Text(isAnswerCorrect ? "正解 ✅" : "不正解 ❌")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(isAnswerCorrect ? Color.themeCorrect : Color.themeIncorrect)
                        .cornerRadius(8)
                    Spacer()
                }

                Text(quiz.question)
                    .font(.title3)
                    .fontWeight(.bold)
                    .padding(.top, 4)
                    .foregroundColor(.themeTextPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                        choiceRow(
                            for: choice,
                            isCorrectChoice: index == quiz.answerIndex,
                            isSelectedChoice: index == selectedAnswerIndex,
                            isAnswerCorrect: isAnswerCorrect
                        )
                    }
                }
                .padding(.vertical, 4)

                Divider()

                if let explanation = explanationText, !explanation.isEmpty {
                    Text(explanation)
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

                Spacer(minLength: 80)
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
        .safeAreaInset(edge: .bottom) {
            Button(action: { handleNextAction() }) {
                Text(hasNextQuestion ? "次の問題へ" : "復習を終了")
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
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension IncorrectAnswerExplanationView {
    var explanationText: String? {
        guard let text = quiz.explanation?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    func choiceRow(
        for text: String,
        isCorrectChoice: Bool,
        isSelectedChoice: Bool,
        isAnswerCorrect: Bool
    ) -> some View {
        let tags = choiceTags(isCorrectChoice: isCorrectChoice, isSelectedChoice: isSelectedChoice)
        let highlightColor = choiceHighlightColor(
            isCorrectChoice: isCorrectChoice,
            isSelectedChoice: isSelectedChoice,
            isAnswerCorrect: isAnswerCorrect
        )

        return HStack(alignment: .center, spacing: 12) {
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

    enum ChoiceTagType: String {
        case correct = "正解"
        case selected = "回答"
    }

    func choiceTags(isCorrectChoice: Bool, isSelectedChoice: Bool) -> [ChoiceTagType] {
        var tags: [ChoiceTagType] = []
        if isCorrectChoice { tags.append(.correct) }
        if isSelectedChoice { tags.append(.selected) }
        return tags
    }

    func choiceHighlightColor(
        isCorrectChoice: Bool,
        isSelectedChoice: Bool,
        isAnswerCorrect: Bool
    ) -> Color? {
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

    func tagView(for type: ChoiceTagType, isAnswerCorrect: Bool) -> some View {
        let color: Color
        switch type {
        case .correct:
            color = Color.themeCorrect
        case .selected:
            color = isAnswerCorrect ? Color.themeCorrect : Color.themeIncorrect
        }

        return Text(type.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color))
    }

    func handleNextAction() {
        onNext()
    }
}
