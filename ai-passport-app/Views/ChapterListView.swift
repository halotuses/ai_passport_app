import SwiftUI

/// 章選択画面
struct ChapterListView: View {
    
    let unitKey: String
    
    let unit: QuizMetadata
    @ObservedObject var viewModel: ChapterListViewModel
    @Binding var selectedChapter: ChapterMetadata?
    @EnvironmentObject private var mainViewState: MainViewState
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(viewModel.chapters, id: \.self) { chapter in
                    Button(action: { selectedChapter = chapter }) {
                        chapterRowView(chapter: chapter)
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
    
    private func chapterRowView(chapter: ChapterMetadata) -> some View {
        let totalCount = viewModel.quizCounts[chapter.id] ?? 0
        let correctCount = viewModel.correctCounts[chapter.id] ?? 0
        
        return HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.themeMain)
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text("正解数 / 問題数")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.themeMain.opacity(0.18))
                    .frame(width: 50, height: 50)
                Text("\(correctCount)/\(totalCount)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
            }
        }
        .padding(12)
        .background(Color.themeSurfaceElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
        )
    }
}
