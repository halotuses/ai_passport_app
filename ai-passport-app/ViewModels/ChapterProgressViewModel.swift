import Foundation
@preconcurrency import RealmSwift

protocol ChapterProgressDisplayable: ObservableObject, Identifiable {
    var chapter: ChapterMetadata { get }
    var wordPair: ChapterMetadata.WordPair? { get }
    var correctCount: Int { get }
    var answeredCount: Int { get }
    var totalQuestions: Int { get }
    var accuracyRate: Double { get }
}

@MainActor
final class ChapterProgressViewModel: ObservableObject, Identifiable {
    let id: String
    let chapter: ChapterMetadata

    @Published private(set) var correctCount: Int = 0
    @Published private(set) var answeredCount: Int = 0
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var accuracyRate: Double = 0

    private let repository: RealmAnswerHistoryRepository
    private let realmConfiguration: Realm.Configuration
    private let realmManager: RealmManager
    private let unitIdentifier: String
    private let chapterIdentifier: String
    private let chapterNumericId: Int
    private var progressToken: NotificationToken?
    private var progressResults: Results<QuestionProgressObject>?

    init(
        unitId: String,
        chapter: ChapterMetadata,
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository(),
        realmManager: RealmManager = .shared
    ) {
        self.chapter = chapter
        self.repository = repository
        self.id = chapter.id
        self.unitIdentifier = unitId
        self.chapterIdentifier = chapter.id
        self.chapterNumericId = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapter.id)
        self.realmConfiguration = repository.realmConfiguration
        self.realmManager = realmManager

        loadInitialProgress()
        observeProgressChanges()
        
    }

    func updateTotalQuestions(_ count: Int) {
        guard count != totalQuestions else { return }
        totalQuestions = count
        recalculateAccuracyRate()
    }

    func refresh() {
        loadInitialProgress()
    }

    private func loadInitialProgress() {
        let stringBasedCorrect = repository.countCorrectAnswers(unitId: unitIdentifier, chapterIdentifier: chapterIdentifier)
        let stringBasedAnswered = repository.answeredCount(unitId: unitIdentifier, chapterIdentifier: chapterIdentifier)

        if stringBasedCorrect == 0 && stringBasedAnswered == 0 {
            correctCount = repository.countCorrectAnswers(for: chapterNumericId)
            answeredCount = repository.answeredCount(for: chapterNumericId)
        } else {
            correctCount = stringBasedCorrect
            answeredCount = stringBasedAnswered
        }
        recalculateAccuracyRate()
    }

    private func observeProgressChanges() {
        do {
            let realm = try realmManager.realm(configuration: realmConfiguration)
            let results = realm.objects(QuestionProgressObject.self)
                .filter(
                    "(unitIdentifier == %@ AND chapterIdentifier == %@) OR chapterId == %d",
                    unitIdentifier,
                    chapterIdentifier,
                    chapterNumericId
                )
            progressResults = results

            progressToken = results.observe { [weak self] changes in
                guard let self else { return }
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let correct = collection
                        .filter("statusRaw == %@", QuestionStatus.correct.rawValue)
                        .count
                    let answered = collection
                        .filter("statusRaw != %@", QuestionStatus.unanswered.rawValue)
                        .count

                    var needsRecalculate = false
                    if correct != self.correctCount {
                        self.correctCount = correct
                        needsRecalculate = true
                    }

                    if answered != self.answeredCount {
                        self.answeredCount = answered
                        needsRecalculate = true
                    }

                    if needsRecalculate || self.totalQuestions == 0 {
                        self.recalculateAccuracyRate()
                    }
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }
        } catch {
            print("❌ Realm observe failed: \(error)")
        }
    }

    private func recalculateAccuracyRate() {
        guard answeredCount > 0 else {
            accuracyRate = 0
            return
        }

        accuracyRate = min(max(Double(correctCount) / Double(answeredCount), 0), 1)
    }

    deinit {
        progressToken?.invalidate()
    }
}
extension ChapterProgressViewModel: ChapterProgressDisplayable {
    var wordPair: ChapterMetadata.WordPair? { chapter.wordPair }
}
