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
        let progress = totalCount > 0 ? Double(correctCount) / Double(totalCount) : 0
        
        
        return HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text("正解数 / 問題数")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            CircularProgressView(
                progress: progress,
                correctCount: correctCount,
                totalCount: totalCount
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
private struct CircularProgressView: View {
    let progress: Double
    let correctCount: Int
    let totalCount: Int
    
    private let size: CGFloat = 56
    private let lineWidth: CGFloat = 6
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeSecondary.opacity(0.18), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.themeMain, Color.themeSecondary]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            Text("\(correctCount)/\(totalCount)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.themeTextPrimary)
        }
        .frame(width: size, height: size)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.6), radius: 6, x: 0, y: 3)
    }
}
