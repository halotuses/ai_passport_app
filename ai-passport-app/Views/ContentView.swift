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
            if let route = activeExplanationRoute {
                ExplanationView(
                    viewModel: viewModel,
                    quiz: route.quiz,
                    selectedAnswerIndex: route.selectedAnswerIndex,
                    primaryButtonTitle: mainViewState.isShowingBookmarkQuiz ? "ブックマークに戻る" : nil,
                    primaryAction: mainViewState.isShowingBookmarkQuiz ? {
                        mainViewState.returnFromBookmarkQuiz(router: router)
                    } : nil,
                    onNext: handleExplanationNext
                )
            } else {
                contentBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase)
        .animation(.none, value: activeExplanationRoute)
        .onAppear(perform: handleOnAppear)
        .onChange(of: chapter.id, perform: handleChapterChange)
        .onChange(of: viewModel.currentQuestionIndex, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.quizzes.count, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.isLoaded, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.hasError, perform: { _ in refreshHeader() })
        .onChange(of: viewModel.bookmarkedQuizIds, perform: { _ in refreshHeader() })
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
                onRestart: handleRestart,
                onBackToChapterSelection: onBackToChapterSelection,
                onBackToUnitSelection: onBackToUnitSelection,
                onImmediatePersist: viewModel.persistAllStatusesImmediately
            )
        case .question:
            QuizContentView(
                viewModel: viewModel,
                isExplanationPresented: activeExplanationRoute != nil,
                onSelectAnswer: handleAnswerSelection
            )
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
            closeExplanation()
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
        mainViewState.clearHeaderBookmark()
    }
    
    func handleAnswerSelection(_ selectedIndex: Int) {
        guard let quiz = viewModel.currentQuiz else { return }
        viewModel.recordAnswer(selectedIndex: selectedIndex)
        showExplanation(for: quiz, selectedAnswerIndex: selectedIndex)
    }
    
    func handleExplanationNext() {
        closeExplanation()
    }
    
    func refreshHeader() {
        updateHeaderForCurrentState()
    }
    func showExplanation(for quiz: Quiz, selectedAnswerIndex: Int) {
        let route = ExplanationRoute(
            quiz: quiz,
            selectedAnswerIndex: selectedAnswerIndex
        )
        activeExplanationRoute = route
        updateHeaderForCurrentState()
    }
    
    func closeExplanation() {
        activeExplanationRoute = nil
        updateHeaderForCurrentState()
    }
    
    func handleRestart() {
        closeExplanation()
        viewModel.restartQuiz()
        refreshHeader()
    }
    
    func loadQuizzes() {
        let chapterFilePath = chapter.file
        let unitId = extractUnitIdentifier(from: chapterFilePath)
        if viewModel.isLoaded,
           viewModel.chapterId == chapter.id,
           viewModel.unitId == unitId {
            return
        }
        viewModel.unitId = unitId
        viewModel.chapterId = chapter.id
        viewModel.fetchQuizzes(from: chapterFilePath)
    }
    
    func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        for component in components where component.hasPrefix("unit") {
            let suffix = component.dropFirst("unit".count)
            if !suffix.isEmpty && suffix.allSatisfy({ $0.isNumber }) {
                return String(component)
            }
        }
        return ""
    }
    
    
    func updateHeaderForCurrentState() {
        let isBookmarkQuiz = mainViewState.isShowingBookmarkQuiz
        let bookmarkBackButton = MainViewState.HeaderBackButton(
            title: "◀ ブックマーク",
            destination: .custom,
            action: { [weak mainViewState, weak router] in
                guard let mainViewState, let router else { return }
                mainViewState.returnFromBookmarkQuiz(router: router)
            }
        )
        let bookmarkQuiz: Quiz?
        if activeExplanationRoute != nil {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            mainViewState.setHeader(title: "第\(questionNumber)問 解説", backButton: .toQuizQuestion)
            bookmarkQuiz = activeExplanationRoute?.quiz
        } else if viewModel.totalCount > 0 && viewModel.currentQuestionIndex >= viewModel.totalCount {
            mainViewState.setHeader(title: "結果", backButton: isBookmarkQuiz ? bookmarkBackButton : .toChapterList)
            bookmarkQuiz = nil
        } else if viewModel.isLoaded && viewModel.totalCount > 0 {
            let questionNumber = min(viewModel.currentQuestionIndex + 1, viewModel.totalCount)
            mainViewState.setHeader(title: "第\(questionNumber)問", backButton: isBookmarkQuiz ? bookmarkBackButton : .toChapterList)
            bookmarkQuiz = viewModel.currentQuiz
        } else {
            mainViewState.setHeader(title: chapter.title, backButton: isBookmarkQuiz ? bookmarkBackButton : .toChapterList)
            bookmarkQuiz = nil
        }

        if let quiz = bookmarkQuiz {
            let isBookmarked = viewModel.isBookmarked(quiz: quiz)
            mainViewState.setHeaderBookmark(isActive: isBookmarked) {
                viewModel.toggleBookmark(for: quiz)
                let updated = viewModel.isBookmarked(quiz: quiz)
                mainViewState.updateHeaderBookmarkState(isActive: updated)
            }
        } else {
            mainViewState.clearHeaderBookmark()
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
            
            Button("前に戻る") {
                onQuizEnd()
            }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.themeButtonSecondary)
                .foregroundColor(.themeTextPrimary)
                .cornerRadius(10)
        }
        .padding()
    }
}

// QuizContentView は、問題文と回答選択肢を表示する中核ビュー。
// 問題部分（QuestionView）＋回答部分（AnswerAreaView）で構成される。
private struct QuizContentView: View {
    // 問題データや選択状態などを保持する ViewModel
    @ObservedObject var viewModel: QuizViewModel
    
    // 解説表示中かどうかを判定するフラグ（解説中は回答不可）
    let isExplanationPresented: Bool
    
    // 回答選択時に呼ばれる外部ハンドラ（親ビューに選択結果を伝える）
    let onSelectAnswer: (Int) -> Void
    
    // View のメイン構成
    var body: some View {
        // 縦方向に要素を積むレイアウト
        VStack(spacing: 0) {
            // 問題文などを表示するビュー
            QuestionView(viewModel: viewModel)
                // 上部に余白を追加（見た目調整）
                .padding(.top, 12)
            
            // 可変スペースを入れて下部エリアを押し下げる
            Spacer(minLength: 0)
        }
        // 親コンテナのサイズを最大に広げる
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        // safeAreaInset は、指定した辺に追加ビューを埋め込む SwiftUI のモディファイア。
        // ここでは「画面下部」に回答エリアを固定表示するために使用。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 下部に配置する VStack（区切り線＋回答エリア）
            VStack(spacing: 0) {
                // 区切り線（上との視覚的な境界）
                Divider()
                    // 区切り線の色をテーマカラーに合わせ、透明度で調整
                    .background(Color.themeMain.opacity(0.2))
                    // 上に少し余白をとって配置
                    .padding(.top, 12)

                // 回答選択肢エリア
                AnswerAreaView(
                    // 選択肢データ（なければ空配列）
                    choices: viewModel.currentQuiz?.choices ?? [],
                    // 選択時に handleSelection を呼び出す
                    selectAction: handleSelection
                )
                // 回答エリア上部に余白
                .padding(.top, 8)
                // 回答エリア下部に余白（SafeAreaに収まるよう調整）
                .padding(.bottom, 0)
            }
            // 下部ビューの背景色（画面全体のテーマ色に合わせる）
            .background(Color.themeBase)
        }
    }
    
    // 回答がタップされたときに呼ばれる処理
    private func handleSelection(_ selectedIndex: Int) {
        // 解説画面が出ているときは回答操作を無効化
        guard !isExplanationPresented else { return }
        
        // 親ビューに「どの選択肢が選ばれたか」を伝える
        onSelectAnswer(selectedIndex)
    }
}
