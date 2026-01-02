import SwiftUI

/// 章選択画面
struct ChapterListView: View {
    
    let unitKey: String
    
    let unit: QuizMetadata
    @StateObject private var viewModel: ChapterListViewModel
    @Binding var selectedChapter: ChapterMetadata?
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var progressManager: ProgressManager
    @State private var isPrefetching = false
    
    init(
        unitKey: String,
        unit: QuizMetadata,
        viewModel: ChapterListViewModel,
        selectedChapter: Binding<ChapterMetadata?>
    ) {
        self.unitKey = unitKey
        self.unit = unit
        _viewModel = StateObject(wrappedValue: viewModel)
        _selectedChapter = selectedChapter
    }


    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.progressViewModels) { progressVM in
                    Button(action: {
                        SoundManager.shared.play(.tap)
                        guard !isPrefetching else { return }
                        let chapter = progressVM.chapter
                        isPrefetching = true
                        progressManager.quizViewModel.unitId = unitKey
                        progressManager.quizViewModel.chapterId = chapter.id
                        Task {
                            _ = await progressManager.quizViewModel.prefetchQuizzes(from: chapter.file)
                            selectedChapter = chapter
                            isPrefetching = false
                        }
                    }) {
                        ChapterCardView(viewModel: progressVM)
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .onAppear {
            mainViewState.setHeader(title: unit.title, backButton: .toUnitList)
            viewModel.fetchChapters(forUnitId: unitKey, filePath: unit.file)
        }
    }
}
