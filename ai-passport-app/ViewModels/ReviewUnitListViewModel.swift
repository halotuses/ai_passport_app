import Foundation

@MainActor
final class ReviewUnitListViewModel: ObservableObject {

    struct ReviewUnit: Identifiable, Hashable {
        let id: String
        let unitId: String
        let unit: QuizMetadata
        let chapters: [ReviewChapter]

        var reviewCount: Int {
            chapters.reduce(into: 0) { $0 += $1.reviewCount }
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: ReviewUnit, rhs: ReviewUnit) -> Bool {
            lhs.id == rhs.id
        }
    }

    struct ReviewChapter: Identifiable, Hashable {
        let id: String
        let chapter: ChapterMetadata
        let reviewCount: Int
        let initialQuestionIndex: Int

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: ReviewChapter, rhs: ReviewChapter) -> Bool {
            lhs.id == rhs.id
        }
    }

    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    @Published private(set) var units: [ReviewUnit] = []

    private let progresses: [QuestionProgress]
    private let metadataProvider: () async -> QuizMetadataMap?
    private let chapterListProvider: (String, String) async -> [ChapterMetadata]?
    private var hasLoaded = false

    init(
        progresses: [QuestionProgress],
        metadataProvider: @escaping () async -> QuizMetadataMap?,
        chapterListProvider: @escaping (String, String) async -> [ChapterMetadata]?
    ) {
        self.progresses = progresses
        self.metadataProvider = metadataProvider
        self.chapterListProvider = chapterListProvider
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        guard !isLoading else { return }
        isLoading = true
        hasError = false

        let aggregated = aggregateProgresses()
        guard !aggregated.isEmpty else {
            units = []
            isLoading = false
            hasLoaded = true
            return
        }

        guard let metadataMap = await metadataProvider() else {
            hasError = true
            isLoading = false
            return
        }

        var builtUnits: [ReviewUnit] = []
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
            var entries: [ReviewChapter] = []

            for (chapterId, summary) in chapterInfo {
                guard let metadata = chapterMap[chapterId] else {
                    encounteredError = true
                    continue
                }

                let entry = ReviewChapter(
                    id: chapterId,
                    chapter: metadata,
                    reviewCount: summary.count,
                    initialQuestionIndex: summary.initialQuestionIndex
                )
                entries.append(entry)
            }

            entries.sort(by: chapterSortComparator)

            if !entries.isEmpty {
                builtUnits.append(
                    ReviewUnit(
                        id: unitId,
                        unitId: unitId,
                        unit: unitMetadata,
                        chapters: entries
                    )
                )
            }
        }

        builtUnits.sort { lhs, rhs in
            lhs.unitId.localizedCompare(rhs.unitId) == .orderedAscending
        }

        hasLoaded = true
        units = builtUnits
        hasError = encounteredError && builtUnits.isEmpty
        isLoading = false
    }
}

private extension ReviewUnitListViewModel {
    struct ChapterSummary {
        var count: Int
        var initialQuestionIndex: Int
    }

    func aggregateProgresses() -> [String: [String: ChapterSummary]] {
        var result: [String: [String: ChapterSummary]] = [:]

        for progress in progresses where progress.status != .unanswered {
            guard let components = QuizIdentifierParser.parse(progress.quizId) else { continue }

            let unitId = progress.unitId.isEmpty ? components.unitId : progress.unitId
            let chapterIdentifier = progress.chapterIdentifier.isEmpty ? components.chapterId : progress.chapterIdentifier
            guard !unitId.isEmpty, !chapterIdentifier.isEmpty else { continue }

            let questionIndex = components.questionIndex ?? 0
            var summary = result[unitId, default: [:]][chapterIdentifier] ?? ChapterSummary(count: 0, initialQuestionIndex: questionIndex)
            summary.count += 1
            summary.initialQuestionIndex = min(summary.initialQuestionIndex, questionIndex)
            result[unitId, default: [:]][chapterIdentifier] = summary
        }

        return result
    }

    func chapterSortComparator(_ lhs: ReviewChapter, _ rhs: ReviewChapter) -> Bool {
        if lhs.initialQuestionIndex == rhs.initialQuestionIndex {
            return lhs.chapter.title.localizedCompare(rhs.chapter.title) == .orderedAscending
        }
        return lhs.initialQuestionIndex < rhs.initialQuestionIndex
    }
}
