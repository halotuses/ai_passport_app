import SwiftUI

struct CorrectAnswerView: View {


    let progresses: [QuestionProgress]
    let metadataProvider: () async -> QuizMetadataMap?
    let chapterListProvider: (String, String) async -> [ChapterMetadata]?
    let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState

    @State private var isLoading = true
    @State private var units: [UnitEntry] = []
    @State private var hasError = false

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
private extension CorrectAnswerView {
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
                Text("正解した問題の情報を取得できませんでした。")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else if units.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle")
                    .font(.largeTitle)
                    .foregroundColor(.themeCorrect)
                Text("正解した問題はまだありません。")
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
                            CorrectAnswerChapterView(
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
                    Text("正解済み \(unit.totalCorrectCount) 問")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeCorrect)

                    Text("正解した章数: \(unit.chapters.count)")
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
        mainViewState.setHeader(title: "正解した問題", backButton: backButton)
    }
    
    func loadDataIfNeeded() async {
        guard isLoading else { return }

        let aggregated = aggregateProgresses()
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
                    .compactMap { entry -> ChapterEntry.QuestionEntry? in
                        let progress = entry.progress
                        return ChapterEntry.QuestionEntry(
                            id: progress.quizId,
                            quizId: progress.quizId,
                            questionIndex: entry.questionIndex,
                            progress: progress
                        )
                    }
                    .sorted { lhs, rhs in
                        if lhs.questionIndex == rhs.questionIndex {
                            return lhs.quizId.localizedCompare(rhs.quizId) == .orderedAscending
                        }
                        return lhs.questionIndex < rhs.questionIndex
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

            entries.sort { $0.chapter.title.localizedCompare($1.chapter.title) == .orderedAscending }

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

    func aggregateProgresses() -> [String: [String: ChapterSummary]] {
        var result: [String: [String: ChapterSummary]] = [:]

        for progress in progresses {
            guard let components = QuizIdentifierParser.parse(progress.quizId) else { continue }

            let unitId = progress.unitId.isEmpty ? components.unitId : progress.unitId
            let chapterId = progress.chapterIdentifier.isEmpty ? components.chapterId : progress.chapterIdentifier
            guard !unitId.isEmpty, !chapterId.isEmpty else { continue }

            let questionIndex = components.questionIndex ?? 0

            var summary = result[unitId, default: [:]][chapterId] ?? ChapterSummary(entries: [])
            summary.entries.append(.init(progress: progress, questionIndex: questionIndex))
            result[unitId, default: [:]][chapterId] = summary
        }

        return result
    }

    func chapterComparator(_ lhs: ChapterEntry, _ rhs: ChapterEntry) -> Bool {
        if lhs.initialQuestionIndex == rhs.initialQuestionIndex {
            return lhs.chapter.title.localizedCompare(rhs.chapter.title) == .orderedAscending
        }
        return lhs.initialQuestionIndex < rhs.initialQuestionIndex
    }
}

private extension CorrectAnswerView {
    struct ChapterSummary {
        struct Entry {
            let progress: QuestionProgress
            let questionIndex: Int
        }

        var entries: [Entry]
    }
}

extension CorrectAnswerView {
    struct UnitEntry: Identifiable, Hashable {
        let id: String
        let unitId: String
        let unit: QuizMetadata
        let chapters: [ChapterEntry]
        var totalCorrectCount: Int {
            chapters.reduce(into: 0) { $0 += $1.correctCount }
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
            let progress: QuestionProgress

            var questionText: String {
                if let text = progress.questionText, !text.isEmpty {
                    return text
                }
                return "問題ID: \(quizId)"
            }
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
        var correctCount: Int { questions.count }

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
    CorrectAnswerView(
        progresses: [],
        metadataProvider: { [:] },
        chapterListProvider: { _, _ in [] },
        onClose: {}
    )
    .environmentObject(MainViewState())
}
