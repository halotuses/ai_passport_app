import SwiftUI

/// 中央コンテンツ領域の状態に応じたビューを切り替える
struct ContentStateView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var progressManager: ProgressManager

    @ObservedObject var unitListViewModel: UnitListViewModel
    @Binding var selectedUnit: QuizMetadata?
    @Binding var selectedChapter: ChapterMetadata?

    let onQuizEnd: () -> Void
    let onBackToChapterSelection: () -> Void
    let onBackToUnitSelection: () -> Void

    var body: some View {
        Group {
            if mainViewState.isOnHome {
                HomeView(viewModel: progressManager.homeViewModel)
            } else if selectedUnit == nil {
                UnitListView(
                    viewModel: unitListViewModel,
                    selectedUnit: $selectedUnit
                )
            } else if let unit = selectedUnit, selectedChapter == nil {
                ChapterListView(
                    unitKey: mainViewState.selectedUnitKey ?? "unknown",
                    unit: unit,
                    viewModel: progressManager.chapterListViewModel,
                    selectedChapter: $selectedChapter
                )
            } else if let chapter = selectedChapter {
                ContentView(
                    chapter: chapter,
                    viewModel: progressManager.quizViewModel,
                    onQuizEnd: onQuizEnd,
                    onBackToChapterSelection: onBackToChapterSelection,
                    onBackToUnitSelection: onBackToUnitSelection
                )
            } else {
                EmptyView()
            }
        }
    }
}
