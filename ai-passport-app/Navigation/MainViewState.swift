import SwiftUI

/// アプリ全体のメイン画面状態を管理
final class MainViewState: ObservableObject {
    struct HeaderBackButton: Equatable {
        enum Destination {
            case unitList
            case chapterList
        }
        
        let title: String
        let destination: Destination
    }
    
    @Published var selectedUnit: QuizMetadata? = nil
    @Published var selectedChapter: ChapterMetadata? = nil
    @Published var selectedUnitKey: String? = nil
    @Published var navigationResetToken = UUID()
    @Published var showResultView: Bool = false
    @Published var headerTitle: String = "ホーム"
    @Published var headerBackButton: HeaderBackButton? = nil
    @Published var isOnHome: Bool = true
    
    /// ホーム画面（単元選択）に戻す
    func reset(router: NavigationRouter) {
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        router.reset()
        navigationResetToken = UUID()
        showResultView = false
        enterHome()
    }
    
    
    /// 章選択画面へ戻す
    func backToChapterSelection(router: NavigationRouter) {
        guard selectedUnit != nil else {
            backToUnitSelection(router: router)
            return
        }

        selectedChapter = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()

        let unitTitle = selectedUnit?.title ?? "章選択"
        setHeader(title: unitTitle, backButton: .toUnitList)
    }

    /// 単元選択画面へ戻す
    func backToUnitSelection(router: NavigationRouter) {
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        showResultView = false
        router.reset()
        navigationResetToken = UUID()

        enterUnitSelection()
    }
    
    /// ホーム画面に遷移
    func enterHome() {
        isOnHome = true
        setHeader(title: "ホーム")
    }
    
    /// 単元一覧（学習開始画面）に遷移
    func enterUnitSelection() {
        isOnHome = false
        setHeader(title: "学習アプリ")
        
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
    
    func handleBackAction(_ backButton: HeaderBackButton, router: NavigationRouter) {
        switch backButton.destination {
        case .unitList:
            reset(router: router)
        case .chapterList:
            backToChapterSelection(router: router)
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
}
