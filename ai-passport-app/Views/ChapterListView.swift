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
        .background(Color(red: 240/255, green: 255/255, blue: 240/255))
        .onAppear {
            mainViewState.setHeader(title: unit.title)
            viewModel.fetchChapters(forUnitId: unitKey, filePath: unit.file)
        }
    }
    
    private func chapterRowView(chapter: ChapterMetadata) -> some View {
        let totalCount = viewModel.quizCounts[chapter.id] ?? 0
        let correctCount = viewModel.correctCounts[chapter.id] ?? 0
        
        return HStack {
            Image(systemName: "book.closed")
            Text(chapter.title)
                .font(.system(size: 16, weight: .bold))
            Spacer()
            ZStack {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 50, height: 50)
                Text("\(correctCount)/\(totalCount)")
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .padding(10)
        .background(Color(white: 0.97))
        .cornerRadius(8)
    }
}
