import SwiftUI

struct BookmarkUnitView: View {
    let bookmarks: [BookmarkItem]
    let metadataProvider: () async -> QuizMetadataMap?
    let chapterListProvider: (String, String) async -> [ChapterMetadata]?
    let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState

    @State private var isLoading = true
    @State private var hasError = false
    @State private var units: [UnitEntry] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.themeBase
                    .ignoresSafeArea()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarBackButtonHidden(true)
            .task { await loadDataIfNeeded() }
            .onAppear { setRootHeader() }
        }
    }
}

private extension BookmarkUnitView {
    @ViewBuilder
    var content: some View {
        if isLoading {
            ProgressView("読み込み中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if hasError {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.themeIncorrect)
                Text("ブックマークした問題の情報を取得できませんでした。")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else if units.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.largeTitle)
                    .foregroundColor(.themeTextSecondary)
                Text("ブックマークした問題はまだありません。")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(units) { unit in
                        NavigationLink {
                            BookmarkChapterView(
                                unit: unit,
                                onClose: { setRootHeader() }
                            )
                        } label: {
                            unitCard(for: unit)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                SoundManager.shared.play(.tap)
                            }
                        )
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    func unitCard(for unit: UnitEntry) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(unit.unit.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                if !unit.unit.subtitle.isEmpty {
                    Text(unit.unit.subtitle)
                        .font(.footnote)
                        .foregroundColor(.themeTextSecondary)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ブックマーク \(unit.totalBookmarkCount) 問")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeAccent)

                    Text("対象の章数: \(unit.chapters.count)")
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.themeSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 8)
    }

    func setRootHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom,
            action: onClose
        )
        mainViewState.setHeader(title: "ブックマークした問題", backButton: backButton)
    }

    func loadDataIfNeeded() async {
        guard isLoading else { return }

        let aggregated = aggregateBookmarks()
        guard !aggregated.isEmpty else {
            await MainActor.run {
                units = []
                hasError = false
                isLoading = false
            }
            return
        }

        guard let metadataMap = await metadataProvider() else {
            await MainActor.run {
                hasError = true
                isLoading = false
            }
            return
        }

        var builtUnits: [UnitEntry] = []
        var encounteredError = false

        for (unitId, chapterInfo) in aggregated {
            guard let unitMetadata = metadataMap[unitId] else {
                encounteredError = true
                continue
            }

            guard let chapters = await chapterListProvider(unitId, unitMetadata.file) else {
                encounteredError = true
                continue
            }

            let chapterMap = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })
            var entries: [ChapterEntry] = []

            for (chapterId, summary) in chapterInfo {
                guard let metadata = chapterMap[chapterId] else {
                    encounteredError = true
                    continue
                }

                let questions = summary.entries
                    .sorted(by: questionSortComparator)
                    .map { entry in
                        ChapterEntry.QuestionEntry(
                            id: entry.item.id,
                            quizId: entry.item.quizId,
                            questionIndex: entry.questionIndex,
                            item: entry.item
                        )
                    }

                guard !questions.isEmpty else { continue }

                entries.append(
                    ChapterEntry(
                        id: chapterId,
                        chapter: metadata,
                        questions: questions
                    )
                )
            }

            entries.sort(by: chapterSortComparator)

            if !entries.isEmpty {
                builtUnits.append(
                    UnitEntry(
                        id: unitId,
                        unitId: unitId,
                        unit: unitMetadata,
                        chapters: entries
                    )
                )
            }
        }

        builtUnits.sort { $0.unit.title.localizedCompare($1.unit.title) == .orderedAscending }

        await MainActor.run {
            units = builtUnits
            hasError = encounteredError && builtUnits.isEmpty
            isLoading = false
        }
    }

    func aggregateBookmarks() -> [String: [String: ChapterSummary]] {
        var result: [String: [String: ChapterSummary]] = [:]

        for bookmark in bookmarks {
            guard let components = QuizIdentifierParser.parse(bookmark.quizId) else { continue }

            let unitId: String
            if let storedUnit = bookmark.progress?.unitId, !storedUnit.isEmpty {
                unitId = storedUnit
            } else {
                unitId = components.unitId
            }

            let chapterId: String
            if let storedChapter = bookmark.progress?.chapterIdentifier, !storedChapter.isEmpty {
                chapterId = storedChapter
            } else {
                chapterId = components.chapterId
            }

            guard !unitId.isEmpty, !chapterId.isEmpty else { continue }

            let questionIndex = max(components.questionIndex ?? 0, 0)
            var summary = result[unitId, default: [:]][chapterId] ?? ChapterSummary(entries: [])
            summary.entries.append(.init(item: bookmark, questionIndex: questionIndex))
            result[unitId, default: [:]][chapterId] = summary
        }

        return result
    }

    func questionSortComparator(_ lhs: ChapterSummary.Entry, _ rhs: ChapterSummary.Entry) -> Bool {
        if lhs.questionIndex == rhs.questionIndex {
            return lhs.item.updatedAt > rhs.item.updatedAt
        }
        return lhs.questionIndex < rhs.questionIndex
    }

    func chapterSortComparator(_ lhs: ChapterEntry, _ rhs: ChapterEntry) -> Bool {
        if lhs.initialQuestionIndex == rhs.initialQuestionIndex {
            return lhs.chapter.title.localizedCompare(rhs.chapter.title) == .orderedAscending
        }
        return lhs.initialQuestionIndex < rhs.initialQuestionIndex
    }
}

private extension BookmarkUnitView {
    struct ChapterSummary {
        struct Entry {
            let item: BookmarkItem
            let questionIndex: Int
        }

        var entries: [Entry]
    }
}

extension BookmarkUnitView {
    struct BookmarkItem: Identifiable, Hashable {
        let id: String
        let quizId: String
        let questionText: String
        let updatedAt: Date
        let progress: QuestionProgress?
        
        static func == (lhs: BookmarkItem, rhs: BookmarkItem) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct UnitEntry: Identifiable, Hashable {
        let id: String
        let unitId: String
        let unit: QuizMetadata
        let chapters: [ChapterEntry]

        var totalBookmarkCount: Int {
            chapters.reduce(into: 0) { $0 += $1.bookmarkCount }
        }
        static func == (lhs: UnitEntry, rhs: UnitEntry) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct ChapterEntry: Identifiable, Hashable {
        struct QuestionEntry: Identifiable, Hashable {
            let id: String
            let quizId: String
            let questionIndex: Int
            let item: BookmarkItem

            var questionText: String {
                if let text = item.progress?.questionText, !text.isEmpty {
                    return text
                }
                if !item.questionText.isEmpty {
                    return item.questionText
                }
                return "問題ID: \(quizId)"
            }

            var progress: QuestionProgress? { item.progress }
            var updatedAt: Date { item.updatedAt }
            
            static func == (lhs: QuestionEntry, rhs: QuestionEntry) -> Bool {
                lhs.id == rhs.id
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
        }

        let id: String
        let chapter: ChapterMetadata
        let questions: [QuestionEntry]

        var bookmarkCount: Int { questions.count }

        var initialQuestionIndex: Int {
            questions.map(\.questionIndex).min() ?? 0
        }

        static func == (lhs: ChapterEntry, rhs: ChapterEntry) -> Bool {
               lhs.id == rhs.id
           }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

#Preview {
    BookmarkUnitView(
        bookmarks: [],
        metadataProvider: { [:] },
        chapterListProvider: { _, _ in [] },
        onClose: {}
    )
    .environmentObject(MainViewState())
}
