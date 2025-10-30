import SwiftUI

struct CorrectReviewChapterSelectionView: View {
    struct Selection: Sendable {
        let unitId: String
        let unit: QuizMetadata
        let chapter: ChapterMetadata
        let initialQuestionIndex: Int
    }

    let progresses: [QuestionProgress]
    let metadataProvider: () async -> QuizMetadataMap?
    let chapterListProvider: (String, String) async -> [ChapterMetadata]?
    let onSelect: @Sendable (Selection) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var isLoading = true
    @State private var groups: [UnitGroup] = []
    @State private var hasError = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("正解した問題")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("閉じる") { dismiss() }
                    }
                }
        }
        .task { await loadDataIfNeeded() }
    }
}

private extension CorrectReviewChapterSelectionView {
    @ViewBuilder
    var content: some View {
        if isLoading {
            ProgressView("読み込み中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.themeBase.ignoresSafeArea())
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
            .background(Color.themeBase.ignoresSafeArea())
        } else if groups.isEmpty {
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
            .background(Color.themeBase.ignoresSafeArea())
        } else {
            List {
                ForEach(groups) { group in
                    Section(header: sectionHeader(for: group)) {
                        ForEach(group.chapters) { chapter in
                            Button {
                                let selection = Selection(
                                    unitId: group.unitId,
                                    unit: group.unit,
                                    chapter: chapter.chapter,
                                    initialQuestionIndex: chapter.initialQuestionIndex
                                )
                                dismiss()
                                DispatchQueue.main.async {
                                    onSelect(selection)
                                }
                            } label: {
                                chapterRow(for: chapter)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Color.themeBase.ignoresSafeArea())
        }
    }

    func sectionHeader(for group: UnitGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(group.unit.title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            if !group.unit.subtitle.isEmpty {
                Text(group.unit.subtitle)
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .textCase(nil)
    }

    func chapterRow(for chapter: ChapterEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.chapter.title)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                Text("正解済み \(chapter.correctCount) 問")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.themeTextSecondary)
        }
        .padding(.vertical, 8)
    }

    func loadDataIfNeeded() async {
        guard isLoading else { return }

        let aggregated = aggregateProgresses()
        guard !aggregated.isEmpty else {
            await MainActor.run {
                groups = []
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

        var builtGroups: [UnitGroup] = []
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

                entries.append(
                    ChapterEntry(
                        id: chapterId,
                        chapter: metadata,
                        correctCount: summary.count,
                        initialQuestionIndex: summary.initialQuestionIndex
                    )
                )
            }

            entries.sort { $0.chapter.title.localizedCompare($1.chapter.title) == .orderedAscending }

            if !entries.isEmpty {
                builtGroups.append(
                    UnitGroup(
                        id: unitId,
                        unitId: unitId,
                        unit: unitMetadata,
                        chapters: entries
                    )
                )
            }
        }

        builtGroups.sort { $0.unit.title.localizedCompare($1.unit.title) == .orderedAscending }

        await MainActor.run {
            groups = builtGroups
            hasError = encounteredError && builtGroups.isEmpty
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

            var summary = result[unitId, default: [:]][chapterId] ?? ChapterSummary(count: 0, initialQuestionIndex: questionIndex)
            summary.count += 1
            summary.initialQuestionIndex = min(summary.initialQuestionIndex, questionIndex)
            result[unitId, default: [:]][chapterId] = summary
        }

        return result
    }
}

private extension CorrectReviewChapterSelectionView {
    struct UnitGroup: Identifiable {
        let id: String
        let unitId: String
        let unit: QuizMetadata
        let chapters: [ChapterEntry]
    }

    struct ChapterEntry: Identifiable {
        let id: String
        let chapter: ChapterMetadata
        let correctCount: Int
        let initialQuestionIndex: Int
    }

    struct ChapterSummary {
        var count: Int
        var initialQuestionIndex: Int
    }
}

#Preview {
    CorrectReviewChapterSelectionView(
        progresses: [],
        metadataProvider: { [:] },
        chapterListProvider: { _, _ in [] },
        onSelect: { _ in }
    )
}
