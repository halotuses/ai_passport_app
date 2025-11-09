import SwiftUI

struct ReviewPlayView: View {
    struct ExplanationRoute: Identifiable {
        let id = UUID()
        let quiz: Quiz
        let selectedAnswerIndex: Int
    }

    let category: ReviewCategory
    let selection: ReviewUnitSelection
    let onClose: () -> Void

    @StateObject private var viewModel: ReviewPlayViewModel
    @State private var activeExplanationRoute: ExplanationRoute?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var progressManager: ProgressManager

    init(category: ReviewCategory, selection: ReviewUnitSelection, onClose: @escaping () -> Void) {
        self.category = category
        self.selection = selection
        self.onClose = onClose

        let initialQuestionId = selection.questions.first { $0.questionIndex == selection.initialQuestionIndex }?.quizId

        _viewModel = StateObject(
            wrappedValue: ReviewPlayViewModel(
                category: category,
                unit: selection.unit,
                chapter: selection.chapter,
                questions: selection.questions,
                initialQuestionId: initialQuestionId
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let route = activeExplanationRoute {
                ReviewExplanationView(
                    viewModel: viewModel,
                    quiz: route.quiz,
                    selectedAnswerIndex: route.selectedAnswerIndex,
                    category: category,
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

private extension ReviewPlayView {
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
                ReviewQuestionView(
                    viewModel: viewModel,
                    category: category,
                    onRemoveBookmark: handleBookmarkRemoval
                )
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

    func handleBookmarkRemoval() {
        guard category == .bookmark,
              let question = viewModel.currentQuestion else { return }

        progressManager.removeBookmark(with: question.quizId)
        viewModel.removeCurrentQuestion()

        if viewModel.totalCount == 0 {
            finishReview()
        } else {
            updateHeader()
        }
    }

    func updateHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            finishReview()
        }

        let baseTitle = "\(category.playHeaderPrefix)（\(selection.unit.title)・\(selection.chapter.title)）"

        if activeExplanationRoute != nil, viewModel.totalCount > 0 {
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

private struct ReviewQuestionView: View {
    @ObservedObject var viewModel: ReviewPlayViewModel
    let category: ReviewCategory
    let onRemoveBookmark: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let quiz = viewModel.currentQuiz {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top) {
                        Text(quiz.question)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.themeTextPrimary)

                        Spacer(minLength: 8)

                        if category == .bookmark {
                            Button {
                                SoundManager.shared.play(.tap)
                                onRemoveBookmark()
                            } label: {
                                Label("ブックマーク解除", systemImage: "bookmark.slash")
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.themeAccent.opacity(0.12))
                                    .foregroundColor(.themeAccent)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("ブックマーク解除")
                        }
                    }

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
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                Spacer(minLength: 0)
            }
        }
    }

    func choiceLabel(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ"]
        if labels.indices.contains(index) {
            return labels[index]
        }
        return String(Character(UnicodeScalar(0x41 + index) ?? "A"))
    }
}

private struct ReviewExplanationView: View {
    @ObservedObject var viewModel: ReviewPlayViewModel
    let quiz: Quiz
    let selectedAnswerIndex: Int
    let category: ReviewCategory
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
                        explanationChoiceRow(
                            text: choice,
                            isCorrectChoice: index == quiz.answerIndex,
                            isSelectedChoice: index == selectedAnswerIndex
                        )
                    }
                }
                .padding(.vertical, 4)

                Divider()

                if let explanationText = quiz.explanation?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !explanationText.isEmpty {
                    Text(explanationText)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.themeTextPrimary)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.themeIncorrect)
                        Text("解説データが見つかりません。")
                            .font(.subheadline)
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
            Button(action: { onNext() }) {
                Text(hasNextQuestion ? "次の問題へ" : "一覧に戻る")
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
    }

    func explanationChoiceRow(text: String, isCorrectChoice: Bool, isSelectedChoice: Bool) -> some View {
        let highlightColor: Color? = {
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
        }()

        return HStack(alignment: .center, spacing: 12) {
            Text(text)
                .foregroundColor(.themeTextPrimary)
            Spacer(minLength: 8)
            if isCorrectChoice {
                choiceTag("正解", color: .themeCorrect)
            }
            if isSelectedChoice {
                choiceTag("回答", color: .themeIncorrect)
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

    func choiceTag(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color))
    }
}
