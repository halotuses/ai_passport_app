import SwiftUI
typealias BookmarkView = BookmarkPlayView

struct BookmarkPlayView: View {
    struct ExplanationRoute: Identifiable {
        let id = UUID()
        let quiz: Quiz
        let selectedAnswerIndex: Int
    }

    let unit: BookmarkUnitView.UnitEntry
    let chapter: BookmarkUnitView.ChapterEntry
    let onClose: () -> Void

    @StateObject private var viewModel: BookmarkPlayViewModel
    @State private var activeExplanationRoute: ExplanationRoute?

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewState: MainViewState

    init(
        unit: BookmarkUnitView.UnitEntry,
        chapter: BookmarkUnitView.ChapterEntry,
        initialQuestionId: String? = nil,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.chapter = chapter
        self.onClose = onClose
        _viewModel = StateObject(
            wrappedValue: BookmarkPlayViewModel(
                chapter: chapter,
                initialQuestionId: initialQuestionId
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            if let route = activeExplanationRoute {
                BookmarkExplanationView(
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

private extension BookmarkPlayView {
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
                BookmarkQuestionView(viewModel: viewModel)
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

        let baseTitle = "ブックマーク復習（\(unit.unit.title)・\(chapter.chapter.title)）"

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

private struct BookmarkQuestionView: View {
    @ObservedObject var viewModel: BookmarkPlayViewModel
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
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if handledQuestionIndex != viewModel.currentQuestionIndex {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onChange(of: viewModel.currentQuestionIndex) { newValue in
            handledQuestionIndex = newValue
        }
    }

    func choiceLabel(for index: Int) -> String {
        let symbols = ["A", "B", "C", "D", "E", "F"]
        if symbols.indices.contains(index) {
            return symbols[index]
        }
        return String(index + 1)
    }
}

private struct BookmarkExplanationView: View {
    @ObservedObject var viewModel: BookmarkPlayViewModel
    let quiz: Quiz
    let selectedAnswerIndex: Int
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("問題")
                            .font(.headline)
                            .foregroundColor(.themeTextSecondary)
                        Text(quiz.question)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.themeTextPrimary)
                            .multilineTextAlignment(.leading)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("あなたの回答")
                            .font(.headline)
                            .foregroundColor(.themeTextSecondary)
                        answerReview
                    }

                    if let explanation = quiz.explanation, !explanation.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("解説")
                                .font(.headline)
                                .foregroundColor(.themeTextSecondary)
                            Text(explanation)
                                .font(.body)
                                .foregroundColor(.themeTextPrimary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(24)
            }

            Divider()
                .background(Color.themeMain.opacity(0.2))

            Button(action: onNext) {
                Text(viewModel.hasNextQuestion ? "次の問題へ" : "復習を終了する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.themeMain)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase)
    }

    @ViewBuilder
    private var answerReview: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(quiz.choices.enumerated()), id: \.offset) { index, choice in
                HStack(alignment: .top, spacing: 12) {
                    Text(choiceLabel(for: index))
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(backgroundColor(for: index))
                        .foregroundColor(foregroundColor(for: index))
                        .clipShape(Capsule())

                    Text(choice)
                        .font(.body)
                        .foregroundColor(.themeTextPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.themeSurface)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            }
        }
    }

    private func choiceLabel(for index: Int) -> String {
        let symbols = ["A", "B", "C", "D", "E", "F"]
        if symbols.indices.contains(index) {
            return symbols[index]
        }
        return String(index + 1)
    }

    private func backgroundColor(for index: Int) -> Color {
        if index == quiz.answerIndex {
            return Color.themeCorrect.opacity(0.15)
        } else if index == selectedAnswerIndex {
            return Color.themeIncorrect.opacity(0.15)
        }
        return Color.themePillBackground
    }

    private func foregroundColor(for index: Int) -> Color {
        if index == quiz.answerIndex {
            return .themeCorrect
        } else if index == selectedAnswerIndex {
            return .themeIncorrect
        }
        return .themeTextSecondary
    }
}

#Preview {
    BookmarkPlayView(
        unit: BookmarkUnitView.UnitEntry(
            id: "unit1",
            unitId: "unit1",
            unit: QuizMetadata(version: "1", file: "", title: "サンプル", subtitle: "", total: 0),
            chapters: []
        ),
        chapter: BookmarkUnitView.ChapterEntry(
            id: "chapter1",
            chapter: ChapterMetadata(id: "chapter1", title: "章1", file: ""),
            questions: []
        ),
        initialQuestionId: nil,
        onClose: {}
    )
    .environmentObject(MainViewState())
}
