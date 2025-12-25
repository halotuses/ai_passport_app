import SwiftUI

@MainActor
protocol QuizNavigationCleanupDelegate: AnyObject {
    func prepareForQuizNavigationCleanup()
}

/// アプリ全体のメイン画面状態を管理
@MainActor
final class MainViewState: ObservableObject {
    struct HeaderBackButton: Equatable {
        enum Destination: Equatable {
            case unitList
            case chapterList
            case home
            case quizQuestion
            case custom
        }
        
        let title: String
        let destination: Destination
        let action: (() -> Void)?
        
        init(title: String, destination: Destination, action: (() -> Void)? = nil) {
            self.title = title
            self.destination = destination
            self.action = action
        }
        
        static func == (lhs: HeaderBackButton, rhs: HeaderBackButton) -> Bool {
            lhs.title == rhs.title && lhs.destination == rhs.destination
        }
    }
    
    struct HeaderBookmarkConfiguration {
        let action: () -> Void
        var isActive: Bool
    }
    
    weak var quizCleanupDelegate: QuizNavigationCleanupDelegate?
    var quizCleanupHandler: (() -> Void)?
    var reviewCleanupHandler: (() -> Void)?
    private struct BookmarkReturnState {
        let headerTitle: String
        let headerBackButton: HeaderBackButton?
        let headerBookmark: HeaderBookmarkConfiguration?
        let returnButtonTitle: String
        let isOnHome: Bool
        let isShowingAnswerHistory: Bool
        let isShowingReview: Bool
        let selectedUnit: QuizMetadata?
        let selectedChapter: ChapterMetadata?
        let selectedUnitKey: String?
        let showResultView: Bool
        let navigationPath: NavigationPath
    }
    
    private struct BookmarkQuizReturnState {
        let headerTitle: String
        let headerBackButton: HeaderBackButton?
    }
    
    private var bookmarkReturnState: BookmarkReturnState?
    private var bookmarkQuizReturnState: BookmarkQuizReturnState?
    
    @Published var selectedUnit: QuizMetadata? = nil
    @Published var selectedChapter: ChapterMetadata? = nil
    @Published var selectedUnitKey: String? = nil
    @Published var navigationResetToken = UUID()
    @Published var explanationDismissToken = UUID()
    @Published var showResultView: Bool = false
    @Published var headerTitle: String = "ホーム"
    @Published var headerBackButton: HeaderBackButton? = nil
    @Published var headerBookmark: HeaderBookmarkConfiguration? = nil
    @Published var isOnHome: Bool = true
    @Published var isShowingAnswerHistory: Bool = false
    @Published var isShowingBookmarks: Bool = false
    @Published var isShowingBookmarkQuiz: Bool = false
    @Published var isShowingReview: Bool = false
    @Published var isSuspendingReviewForBookmarks: Bool = false
    
    /// ホーム画面（単元選択）に戻す
    func reset(router: NavigationRouter) {
        prepareForReviewNavigationCleanupIfNeeded()
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        isSuspendingReviewForBookmarks = false
        router.reset()
        navigationResetToken = UUID()
        showResultView = false
        clearHeaderBookmark()
        enterHome()
        bookmarkReturnState = nil
    }
    
    
    
    /// 章選択画面へ戻す
    func backToChapterSelection(router: NavigationRouter) {
        guard selectedUnit != nil else {
            backToUnitSelection(router: router)
            return
        }
        prepareForReviewNavigationCleanupIfNeeded()
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
        
        let unitTitle = selectedUnit?.title ?? "章選択"
        setHeader(title: unitTitle, backButton: .toUnitList)
    }
    
    /// 単元選択画面へ戻す
    func backToUnitSelection(router: NavigationRouter) {
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
        enterUnitSelection()
    }
    
    /// ホーム画面に遷移
    func enterHome() {
        prepareForReviewNavigationCleanupIfNeeded()
        isOnHome = true
        isShowingAnswerHistory = false
        isShowingReview = false
        setHeader(title: "ホーム")
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
    }
    
    /// 単元一覧（学習開始画面）に遷移
    func enterUnitSelection() {
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        setHeader(title: "学習アプリ", backButton: .toHome)
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
        
    }
    
    /// 復習画面に遷移
    func enterReview() {
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = true
        setHeader(title: "復習", backButton: .toHome)
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
    }
    
    /// 回答履歴画面に遷移
    func enterAnswerHistory() {
        isOnHome = false
        isShowingAnswerHistory = true
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        setHeader(title: "回答履歴", backButton: .toHome)
        isSuspendingReviewForBookmarks = false
        clearHeaderBookmark()
    }
    
    func backToHome(router: NavigationRouter) {
        prepareForReviewNavigationCleanupIfNeeded()
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        isShowingReview = false
        isSuspendingReviewForBookmarks = false
        enterHome()
        clearHeaderBookmark()
        bookmarkReturnState = nil
        
    }
    
    /// 結果画面を表示する
    func showResult() {
        showResultView = true
    }
    
    func resetNavigation() {
        navigationResetToken = UUID()
    }
    
    func setHeader(title: String, backButton: HeaderBackButton? = nil) {
        headerTitle = title
        headerBackButton = backButton
    }
    
    func enterBookmarks(router: NavigationRouter) {
        prepareForQuizNavigationCleanupIfNeeded()
        isShowingBookmarkQuiz = false
        let returnButtonTitle: String
        if let existingBackButtonTitle = headerBackButton?.title {
            returnButtonTitle = existingBackButtonTitle
        } else {
            returnButtonTitle = "◀ \(headerTitle)"
        }
        
        bookmarkReturnState = BookmarkReturnState(
            headerTitle: headerTitle,
            headerBackButton: headerBackButton,
            headerBookmark: headerBookmark,
            returnButtonTitle: returnButtonTitle,
            isOnHome: isOnHome,
            isShowingAnswerHistory: isShowingAnswerHistory,
            isShowingReview: isShowingReview,
            selectedUnit: selectedUnit,
            selectedChapter: selectedChapter,
            selectedUnitKey: selectedUnitKey,
            showResultView: showResultView,
            navigationPath: router.path
        )
        let wasShowingReview = isShowingReview
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingBookmarks = true
        isSuspendingReviewForBookmarks = wasShowingReview
        isShowingReview = false
        clearHeaderBookmark()
        setHeader(
            title: "ブックマーク",
            backButton: HeaderBackButton(
                title: bookmarkReturnState?.returnButtonTitle ?? "◀ 戻る",
                destination: .custom,
                action: { [weak self, weak router] in
                    guard let self, let router else { return }
                    self.restoreBookmarkState(router: router)
                }
            )
        )
    }
    
    func enterBookmarkQuiz(
        router: NavigationRouter,
        unitKey: String,
        unit: QuizMetadata,
        chapter: ChapterMetadata
    ) {
        bookmarkQuizReturnState = BookmarkQuizReturnState(
            headerTitle: headerTitle,
            headerBackButton: headerBackButton
        )
        isShowingBookmarks = false
        isShowingBookmarkQuiz = true
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingReview = false
        selectedUnitKey = unitKey
        selectedUnit = unit
        selectedChapter = chapter
        showResultView = false
        clearHeaderBookmark()
        router.reset()
        navigationResetToken = UUID()
    }

    func returnFromBookmarkQuiz(router: NavigationRouter) {
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        isShowingBookmarkQuiz = false
        isShowingBookmarks = true
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingReview = false
        clearHeaderBookmark()
        router.reset()
        navigationResetToken = UUID()
        if let state = bookmarkQuizReturnState {
            setHeader(title: state.headerTitle, backButton: state.headerBackButton)
        } else {
            setHeader(title: "ブックマーク", backButton: headerBackButton)
        }
        bookmarkQuizReturnState = nil
    }
    
    func setHeaderBookmark(isActive: Bool, action: @escaping () -> Void) {
        headerBookmark = HeaderBookmarkConfiguration(action: action, isActive: isActive)
    }
    
    func updateHeaderBookmarkState(isActive: Bool) {
        guard let configuration = headerBookmark else { return }
        headerBookmark = HeaderBookmarkConfiguration(action: configuration.action, isActive: isActive)
    }
    
    func clearHeaderBookmark() {
        headerBookmark = nil
    }
    
    func handleBackAction(_ backButton: HeaderBackButton, router: NavigationRouter) {
        switch backButton.destination {
        case .unitList:
            backToUnitSelection(router: router)
        case .chapterList:
            backToChapterSelection(router: router)
        case .home:
            backToHome(router: router)
        case .quizQuestion:
            explanationDismissToken = UUID()
        case .custom:
            backButton.action?()
        }
    }
    
    
    func makeBackButtonAction(for backButton: HeaderBackButton, router: NavigationRouter) -> () -> Void {
        { [weak self] in
            guard let self else { return }
            self.handleBackAction(backButton, router: router)
        }
    }
    
    func makeHomeButtonAction(router: NavigationRouter) -> () -> Void {
        { [weak self] in
            guard let self else { return }
            self.reset(router: router)
        }
    }
    
    
    private func prepareForQuizNavigationCleanupIfNeeded() {
        if let delegate = quizCleanupDelegate {
            delegate.prepareForQuizNavigationCleanup()
        } else {
            quizCleanupHandler?()
        }
    }
    private func prepareForReviewNavigationCleanupIfNeeded() {
        reviewCleanupHandler?()
        reviewCleanupHandler = nil
    }
    private func restoreBookmarkState(router: NavigationRouter) {
        guard let state = bookmarkReturnState else {
            backToHome(router: router)
            return
        }
        
        bookmarkReturnState = nil
        isShowingBookmarks = false
        isShowingBookmarkQuiz = false
        router.path = state.navigationPath
        isOnHome = state.isOnHome
        isShowingAnswerHistory = state.isShowingAnswerHistory
        isShowingReview = state.isShowingReview
        isSuspendingReviewForBookmarks = false
        selectedUnit = state.selectedUnit
        selectedChapter = state.selectedChapter
        selectedUnitKey = state.selectedUnitKey
        showResultView = state.showResultView
        headerBookmark = state.headerBookmark
        setHeader(title: state.headerTitle, backButton: state.headerBackButton)
    }
}

extension MainViewState.HeaderBackButton {
    /// クイズ画面向け：章一覧に戻るが、ラベルは「単元選択に戻る」
    static let quizToChapterList = Self(title: "◀ 単元", destination: .chapterList)
    /// 章一覧に戻る際の標準ラベル
    static let toChapterList = Self(title: "◀ 章", destination: .chapterList)
    /// 単元一覧に戻る際のラベル
    static let toUnitList = Self(title: "◀ 単元", destination: .unitList)
    /// ホームに戻る際のラベル
    static let toHome = Self(title: "◀ 戻る", destination: .home)
    /// 解説画面から問題画面へ戻る
    static let toQuizQuestion = Self(title: "◀ 問題", destination: .quizQuestion)
    /// シートを閉じるためのボタン
    static func close(action: @escaping () -> Void) -> Self {
        Self(title: "閉じる", destination: .custom, action: action)
    }
}
