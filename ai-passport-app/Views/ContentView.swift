//
//  ContentView.swift
//  ai-passport-app
//

import SwiftUI
struct ContentView: View {
    let chapter: ChapterMetadata
    @ObservedObject var viewModel: QuizViewModel
    let onQuizEnd: () -> Void
    let onBackToChapterSelection: () -> Void
    let onBackToUnitSelection: () -> Void
    
    
    @EnvironmentObject private var mainViewState: MainViewState
    
    @EnvironmentObject private var router: NavigationRouter
    @State private var hasLoaded = false
    @State private var activeExplanationRoute: ExplanationRoute?
    
    private enum QuizViewState {
        case loading
        case empty
        case finished
        case question
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            contentBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase)
        .background(explanationNavigation)
        .onAppear(perform: handleOnAppear)
        .onChange(of: chapter.id, perform: handleChapterChange)
        .onChange(of: viewModel.currentQuestionIndex, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.quizzes.count, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.isLoaded, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.hasError, perform: { _ in refreshHeader() })
        .onChange(of: router.path.count, perform: handleRouterPathChange)
        .onChange(of: activeExplanationRoute, perform: { _ in refreshHeader() })
        .onChange(of: mainViewState.explanationDismissToken, perform: handleExplanationDismiss)
        .onDisappear(perform: handleOnDisappear)
    }
    
    private var viewState: QuizViewState {
        if !viewModel.isLoaded {
            return .loading
        }
        if viewModel.hasError || viewModel.quizzes.isEmpty {
            return .empty
        }
        if viewModel.isFinished {
            return .finished
        }
        return .question
    }
    
    @ViewBuilder
    private var contentBody: some View {
        switch viewState {
        case .loading:
            QuizLoadingView()
        case .empty:
            EmptyQuizStateView(onQuizEnd: onQuizEnd)
        case .finished:
            ResultView(
                correctCount: viewModel.correctCount,
                totalCount: viewModel.totalCount,
                onRestart: onQuizEnd,
                onBackToChapterSelection: onBackToChapterSelection,
                onBackToUnitSelection: onBackToUnitSelection,
                onImmediatePersist: viewModel.persistAllStatusesImmediately
            )
        case .question:#imageLiteral(resourceName: "スクリーンショット 2025-10-27 15.19.34.png")
            QuizContentView(
                viewModel: viewModel,
                isExplanationPresented: activeExplanationRoute != nil,
                onSelectAnswer: handleAnswerSelection
            )
        }
    }
    
    private var explanationNavigation: some View {
        NavigationLink(item: $activeExplanationRoute) { destination in
            ExplanationView(
                viewModel: viewModel,
                quiz: destination.quiz,
                selectedAnswerIndex: destination.selectedAnswerIndex
            )
        } label: {
            EmptyView()
        }
    }
}

private extension ContentView {
    func handleOnAppear() {
        mainViewState.quizCleanupDelegate = viewModel
        refreshHeader()
        guard !hasLoaded else { return }
        loadQuizzes()
        hasLoaded = true
    }
    
    func handleChapterChange(_: ChapterMetadata.ID) {
        refreshHeader()
        loadQuizzes()
    }
    
    func handleRouterPathChange(_ count: Int) {
        if count == 0 {
            activeExplanationRoute = nil
        }
        refreshHeader()
    }
    
    func handleExplanationDismiss(_: UUID) {
        guard activeExplanationRoute != nil else { return }
        closeExplanation()
    }
    
    func handleOnDisappear() {
        if let delegate = mainViewState.quizCleanupDelegate,
           delegate === viewModel {
            mainViewState.quizCleanupDelegate = nil
        }
    }
    
    func handleAnswerSelection(_ selectedIndex: Int) {
        guard let quiz = viewModel.currentQuiz else { return }
        viewModel.recordAnswer(selectedIndex: selectedIndex)
        showExplanation(for: quiz, selectedAnswerIndex: selectedIndex)
    }
    
    func refreshHeader() {
        updateHeaderForCurrentState()
    }
    func showExplanation(for quiz: Quiz, selectedAnswerIndex: Int) {
        activeExplanationRoute = ExplanationRoute(
            quiz: quiz,
            selectedAnswerIndex: selectedAnswerIndex
        )
        
        updateHeaderForCurrentState()
    }
    
    func closeExplanation() {
        guard activeExplanationRoute != nil else { return }
        activeExplanationRoute = nil
        updateHeaderForCurrentState()
    }
    
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
    
    
    func updateHeaderForCurrentState() {
        if activeExplanationRoute != nil {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            mainViewState.setHeader(title: "第\(questionNumber)問 解説", backButton: .toQuizQuestion)
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

private struct QuizLoadingView: View {
    var body: some View {
        ProgressView("読み込み中...")
            .padding()
    }
}

private struct EmptyQuizStateView: View {
    let onQuizEnd: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("問題データが見つかりませんでした。")
                .foregroundColor(.secondary)
            
            Button("前に戻る", action: onQuizEnd)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.themeButtonSecondary)
                .foregroundColor(.themeTextPrimary)
                .cornerRadius(10)
        }
        .padding()
    }
}

private struct QuizContentView: View {
    @ObservedObject var viewModel: QuizViewModel
    let isExplanationPresented: Bool
    let onSelectAnswer: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            QuestionView(viewModel: viewModel)
                .padding(.top, 12)
            
            Spacer(minLength: 0)
            
            Divider()
                .background(Color.themeMain.opacity(0.2))
                .padding(.top, 12)
            
            AnswerAreaView(
                choices: viewModel.currentQuiz?.choices ?? [],
                selectAction: handleSelection
            )
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func handleSelection(_ selectedIndex: Int) {
        guard !isExplanationPresented else { return }
        onSelectAnswer(selectedIndex)
    }
}
