import SwiftUI

struct BookmarkedChapterView: View {
    let unit: BookmarkUnitView.UnitEntry
    let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(unit.chapters) { chapter in
                    NavigationLink {
                        chapterDestination(for: chapter)
                    } label: {
                        chapterRow(chapter)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        SoundManager.shared.play(.tap)
                    })
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .navigationBarBackButtonHidden(true)
        .onAppear { setHeader() }
    }
}

private extension BookmarkedChapterView {
    func setHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "◀ ブックマーク一覧",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "ブックマーク復習（\(unit.unit.title)）"
        mainViewState.setHeader(title: title, backButton: backButton)
    }
    @ViewBuilder
    func chapterDestination(for chapter: BookmarkUnitView.ChapterEntry) -> some View {
        BookmarkPlayView(
            unit: unit,
            chapter: chapter,
            onClose: { setHeader() }
        )
    }

    func chapterRow(_ chapter: BookmarkUnitView.ChapterEntry) -> some View {
        BookmarkCardView(chapter: chapter)
    }
}

#Preview {
    BookmarkedChapterView(
        unit: BookmarkUnitView.UnitEntry(
            id: "unit1",
            unitId: "unit1",
            unit: QuizMetadata(version: "1", file: "", title: "サンプル", subtitle: "", total: 0),
            chapters: []
        ),
        onClose: {}
    )
    .environmentObject(MainViewState())
}
