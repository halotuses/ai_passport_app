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
        HStack(spacing: 16) {
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
                Text(chapter.chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text("ブックマーク \(chapter.bookmarkCount) 問")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }

            Spacer()

            countBubble(total: chapter.bookmarkCount)
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

    func countBubble(total: Int) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.themeSecondary.opacity(0.3), Color.themeMain.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            Text("\(total)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.themeTextPrimary)
        }
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
