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
                    Button(action: { selectedChapter = progressVM.chapter }) {
                        ChapterRowItem(viewModel: progressVM)
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

private struct ChapterRowItem: View {
    @ObservedObject var viewModel: ChapterProgressViewModel

    var body: some View {
        HStack(spacing: 16) {            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)

            }
            Spacer()
            ProgressBadgeView(
                correctCount: viewModel.correctCount,
                totalCount: viewModel.totalQuestions,
                progress: viewModel.progressRate
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 6)
    }
}
