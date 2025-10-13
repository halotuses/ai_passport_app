import SwiftUI

/// アプリ全体のメイン画面状態を管理
final class MainViewState: ObservableObject {
    @Published var selectedUnit: QuizMetadata? = nil
    @Published var selectedChapter: ChapterMetadata? = nil
    @Published var navigationResetToken = UUID()

    /// ホーム画面（単元選択）に戻す
    func reset(router: NavigationRouter) {
        selectedChapter = nil
        selectedUnit = nil
        router.reset()
        navigationResetToken = UUID()
    }
}
