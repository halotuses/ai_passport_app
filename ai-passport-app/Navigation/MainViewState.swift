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
    
    /// ホーム画面（単元選択）に戻す
    func reset(router: NavigationRouter) {
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        router.reset()
        navigationResetToken = UUID()
        showResultView = false
        clearHeaderBookmark()
        enterHome()
    }
    
    
    /// 章選択画面へ戻す
    func backToChapterSelection(router: NavigationRouter) {
        guard selectedUnit != nil else {
            backToUnitSelection(router: router)
            return
        }

        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isShowingAnswerHistory = false
        isShowingBookmarks = false
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
        clearHeaderBookmark()
        enterUnitSelection()
    }
    
    /// ホーム画面に遷移
    func enterHome() {
        isOnHome = true
        isShowingAnswerHistory = false
        setHeader(title: "ホーム")
        isShowingBookmarks = false
        clearHeaderBookmark()
    }
    
    /// 単元一覧（学習開始画面）に遷移
    func enterUnitSelection() {
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        setHeader(title: "学習アプリ", backButton: .toHome)
        clearHeaderBookmark()

    }

    func backToHome(router: NavigationRouter) {
        prepareForQuizNavigationCleanupIfNeeded()
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isShowingAnswerHistory = false
        isShowingBookmarks = false
        enterHome()
        clearHeaderBookmark()
        
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
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()
        isOnHome = false
        isShowingAnswerHistory = false
        isShowingBookmarks = true
        clearHeaderBookmark()
        setHeader(title: "ブックマーク", backButton: .toHome)
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


}

extension MainViewState.HeaderBackButton {
    /// クイズ画面向け：章一覧に戻るが、ラベルは「単元選択に戻る」
    static let quizToChapterList = Self(title: "◀ 単元", destination: .chapterList)
    /// 章一覧に戻る際の標準ラベル
    static let toChapterList = Self(title: "◀ 章", destination: .chapterList)
    /// 単元一覧に戻る際のラベル
    static let toUnitList = Self(title: "◀ 単元", destination: .unitList)
    /// ホームに戻る際のラベル
    static let toHome = Self(title: "◀ ホーム", destination: .home)
    /// 解説画面から問題画面へ戻る
    static let toQuizQuestion = Self(title: "◀ 問題", destination: .quizQuestion)
    /// シートを閉じるためのボタン
    static func close(action: @escaping () -> Void) -> Self {
        Self(title: "閉じる", destination: .custom, action: action)
    }
}
