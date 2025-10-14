//
//  ContentView.swift
//  ai-passport-app
//

import SwiftUI
struct ContentView: View {
    let chapter: ChapterMetadata
    @ObservedObject var viewModel: QuizViewModel
    let onQuizEnd: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState

    @State private var showExplanation = false
    @State private var explanationQuiz: Quiz?
    @State private var explanationSelectedAnswerIndex: Int = 0
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - ロード状態
            if !viewModel.isLoaded {
                ProgressView("読み込み中...")
                    .padding()
            }

            // MARK: - エラーまたはデータ無し
            else if viewModel.hasError || viewModel.quizzes.isEmpty {
                VStack(spacing: 12) {
                    Text("問題データが見つかりませんでした。")
                        .foregroundColor(.secondary)

                    Button("前に戻る") {
                        onQuizEnd()
                    }
                }
                .padding()
            }

            // MARK: - クイズ完了
            else if viewModel.isFinished {
                ResultView(
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.totalCount,
                    onRestart: onQuizEnd
                )
            }

            // MARK: - 問題画面
            else {
                VStack(spacing: 0) {
                    QuestionView(viewModel: viewModel)
                        .padding(.top, 12)

                    Spacer(minLength: 0)

                    Divider()
                        .background(Color.themeMain.opacity(0.2))
                        .padding(.top, 12)

                    AnswerAreaView(
                        choices: viewModel.currentQuiz?.choices ?? [],
                        selectAction: { selectedIndex in
                            viewModel.recordAnswer(selectedIndex: selectedIndex)
                            explanationQuiz = viewModel.currentQuiz
                            explanationSelectedAnswerIndex = selectedIndex
                            showExplanation = true
                        }
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase)
        .sheet(isPresented: $showExplanation) {
            if let quiz = explanationQuiz {
                ExplanationView(
                    quiz: quiz,
                    selectedAnswerIndex: explanationSelectedAnswerIndex,
                    hasNextQuestion: viewModel.hasNextQuestion,
                    onNextQuestion: {
                        proceedToNextQuestion()
                    },
                    onShowResult: {
                        finishQuiz()
                    },
                    onDismiss: {
                        closeExplanation()
                    }
                )
            }
        }
        .onAppear {
            updateHeaderForCurrentState()
            guard !hasLoaded else { return }
            loadQuizzes()
            hasLoaded = true
        }
        .onChange(of: chapter.id) { _ in
            updateHeaderForCurrentState()
            loadQuizzes()
        }
        .onChange(of: viewModel.currentQuestionIndex) { _ in
            updateHeaderForCurrentState()
        }
        .onChange(of: viewModel.quizzes.count) { _ in
            updateHeaderForCurrentState()
        }
        .onChange(of: viewModel.isLoaded) { _ in
            updateHeaderForCurrentState()
        }
        .onChange(of: viewModel.hasError) { _ in
            updateHeaderForCurrentState()
        }
        .onChange(of: showExplanation) { _ in
            updateHeaderForCurrentState()
        }
    }
}

private extension ContentView {
    func loadQuizzes() {
        let chapterFilePath = chapter.file
        viewModel.unitId = extractUnitIdentifier(from: chapterFilePath)
        viewModel.chapterId = chapter.id
        viewModel.fetchQuizzes(from: chapterFilePath)
    }

    func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        if let unitComponent = components.first(where: { $0.hasPrefix("unit") }) {
            return String(unitComponent)
        }
        return ""
    }

    func closeExplanation() {
        showExplanation = false
        explanationQuiz = nil
        explanationSelectedAnswerIndex = 0
    }

    func proceedToNextQuestion() {
        viewModel.moveNext()
        viewModel.selectedAnswerIndex = nil
        closeExplanation()
    }

    func finishQuiz() {
        viewModel.finishQuiz()
        closeExplanation()
    }
    
    
    func updateHeaderForCurrentState() {
        if showExplanation {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            mainViewState.setHeader(title: "第\(questionNumber)問", backButton: .toChapterList)
        } else if viewModel.totalCount > 0 && viewModel.currentQuestionIndex >= viewModel.totalCount {
            mainViewState.setHeader(title: "結果", backButton: .toChapterList)
        } else if viewModel.isLoaded && viewModel.totalCount > 0 {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            mainViewState.setHeader(title: "第\(questionNumber)問", backButton: .toChapterList)
        } else {
            mainViewState.setHeader(title: chapter.title, backButton: .toChapterList)
        }
    }
    
}
