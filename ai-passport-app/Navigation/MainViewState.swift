import SwiftUI

/// アプリ全体のメイン画面状態を管理
final class MainViewState: ObservableObject {
    @Published var selectedUnit: QuizMetadata? = nil
    @Published var selectedChapter: ChapterMetadata? = nil
    @Published var selectedUnitKey: String? = nil
    @Published var navigationResetToken = UUID()
    @Published var showResultView: Bool = false 

    /// ホーム画面（単元選択）に戻す
    func reset(router: NavigationRouter) {
        selectedChapter = nil
        selectedUnit = nil
        selectedUnitKey = nil
        router.reset()
        navigationResetToken = UUID()
    }

    /// 結果画面を表示する
    func showResult() {
        showResultView = true
    }

    func resetNavigation() {
        navigationResetToken = UUID()
    }
}
