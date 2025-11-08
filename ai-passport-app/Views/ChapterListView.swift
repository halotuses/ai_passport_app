import SwiftUI

/// 章選択画面
struct ChapterListView: View {
    
    let unitKey: String
    
    let unit: QuizMetadata
    @StateObject private var viewModel: ChapterListViewModel
    @Binding var selectedChapter: ChapterMetadata?
    @EnvironmentObject private var mainViewState: MainViewState
    
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
                        selectedChapter = progressVM.chapter
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
