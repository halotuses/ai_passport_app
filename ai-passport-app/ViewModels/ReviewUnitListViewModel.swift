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
        
        var chapterCount: Int {
            chapters.count
        }
        
        var statistics: ReviewStatistics {
            var correct = 0
            var answered = 0

            for chapter in chapters {
                for question in chapter.questions {
                    if question.progress.status == .correct {
                        correct += 1
                    }
                    if question.progress.status.isAnswered {
                        answered += 1
                    }
                }
            }

            return ReviewStatistics(
                correctCount: correct,
                answeredCount: answered,
                totalCount: reviewCount
            )
        }

        var hasReviewTargets: Bool { reviewCount > 0 }

        struct ReviewStatistics {
            let correctCount: Int
            let answeredCount: Int
            let totalCount: Int

            var accuracy: Double {
                guard answeredCount > 0 else { return 0 }
                return min(max(Double(correctCount) / Double(answeredCount), 0), 1)
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: ReviewUnit, rhs: ReviewUnit) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    struct ReviewChapter: Identifiable, Hashable {
        struct ReviewQuestion: Identifiable, Hashable {
            let id: String
            let quizId: String
            let questionIndex: Int
            let progress: QuestionProgress
            let updatedAt: Date
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(id)
            }
            
            static func == (lhs: ReviewQuestion, rhs: ReviewQuestion) -> Bool {
                lhs.id == rhs.id
            }
        }
        let id: String
        let chapter: ChapterMetadata
        let reviewCount: Int
        let initialQuestionIndex: Int
        let questions: [ReviewQuestion]
        
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
    private let shouldInclude: (QuestionProgress) -> Bool
    private var hasLoaded = false
    
    init(
        progresses: [QuestionProgress],
        metadataProvider: @escaping () async -> QuizMetadataMap?,
        chapterListProvider: @escaping (String, String) async -> [ChapterMetadata]?,
        shouldInclude: @escaping (QuestionProgress) -> Bool = { _ in true }
    ) {
        self.progresses = progresses
        self.metadataProvider = metadataProvider
        self.chapterListProvider = chapterListProvider
        self.shouldInclude = shouldInclude
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
        guard let metadataMap = await metadataProvider() else {
            hasError = true
            isLoading = false
            return
        }
        
        var builtUnits: [ReviewUnit] = []
        var encounteredError = false
        
        let metadataUnitIds = metadataMap.keys.sorted { $0.localizedCompare($1) == .orderedAscending }

        let aggregatedUnitIds = Set(aggregated.keys)
        let missingUnitIds = aggregatedUnitIds.subtracting(metadataMap.keys)
        if !missingUnitIds.isEmpty {
            encounteredError = true
        }

        for unitId in metadataUnitIds {
            guard let unitMetadata = metadataMap[unitId] else { continue }

            let chapterInfo = aggregated[unitId] ?? [:]
            var entries: [ReviewChapter] = []
            
            if !chapterInfo.isEmpty {
                guard let chapters = await chapterListProvider(unitId, unitMetadata.file) else {
                    encounteredError = true
                    continue
                }
                
                let chapterMap = Dictionary(uniqueKeysWithValues: chapters.map { ($0.id, $0) })

                for (chapterId, summary) in chapterInfo {
                    guard let metadata = chapterMap[chapterId] else {
                        encounteredError = true
                        continue
                    }
                    let questions = summary.entries
                        .map { entry -> ReviewChapter.ReviewQuestion in
                            ReviewChapter.ReviewQuestion(
                                id: entry.progress.quizId,
                                quizId: entry.progress.quizId,
                                questionIndex: entry.questionIndex,
                                progress: entry.progress,
                                updatedAt: entry.progress.updatedAt
                            )
                        }
                        .sorted { lhs, rhs in
                            if lhs.questionIndex == rhs.questionIndex {
                                return lhs.quizId.localizedCompare(rhs.quizId) == .orderedAscending
                            }
                            return lhs.questionIndex < rhs.questionIndex
                        }
                    guard !questions.isEmpty else { continue }

                    let entry = ReviewChapter(
                        id: chapterId,
                        chapter: metadata,
                        reviewCount: questions.count,
                        initialQuestionIndex: questions.first?.questionIndex ?? 0,
                        questions: questions
                    )
                    entries.append(entry)
                }

                entries.sort(by: chapterSortComparator)

                if entries.isEmpty {
                    // 章情報取得時に失敗した場合はエラー扱いとする
                    encounteredError = true
                    continue
                }
            }
            if !entries.isEmpty || chapterInfo.isEmpty {
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
        hasLoaded = true
        units = builtUnits
        hasError = encounteredError && builtUnits.allSatisfy { !$0.hasReviewTargets }
        isLoading = false
    }
}

private extension ReviewUnitListViewModel {
    struct ChapterSummary {
        struct Entry {
            let progress: QuestionProgress
            let questionIndex: Int
        }
        
        var entries: [Entry]
        
        var count: Int { entries.count }
        
        var initialQuestionIndex: Int {
            entries.map(\.questionIndex).min() ?? 0
        }
    }
    
    func aggregateProgresses() -> [String: [String: ChapterSummary]] {
        var result: [String: [String: ChapterSummary]] = [:]
        for progress in progresses where shouldInclude(progress) {
            guard let components = QuizIdentifierParser.parse(progress.quizId) else { continue }
            
            let unitId = progress.unitId.isEmpty ? components.unitId : progress.unitId
            let chapterIdentifier = progress.chapterIdentifier.isEmpty ? components.chapterId : progress.chapterIdentifier
            guard !unitId.isEmpty, !chapterIdentifier.isEmpty else { continue }
            
            let questionIndex = components.questionIndex ?? 0
            var summary = result[unitId, default: [:]][chapterIdentifier] ?? ChapterSummary(entries: [])
            summary.entries.append(.init(progress: progress, questionIndex: questionIndex))
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
