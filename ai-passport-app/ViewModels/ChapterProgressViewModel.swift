import Foundation
import RealmSwift

@MainActor
final class ChapterProgressViewModel: ObservableObject, Identifiable {
    let id: String
    let chapter: ChapterMetadata

    @Published private(set) var correctCount: Int = 0
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var progressRate: Double = 0

    private let repository: RealmAnswerHistoryRepository
    private let realmConfiguration: Realm.Configuration
    private let chapterNumericId: Int
    private var progressToken: NotificationToken?
    private var answerHistoryObserver: NSObjectProtocol?
    private var progressResults: Results<QuestionProgressObject>?

    init(
        unitId: String,
        chapter: ChapterMetadata,
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()
    ) {
        self.chapter = chapter
        self.repository = repository
        self.id = chapter.id
        self.chapterNumericId = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapter.id)
        self.realmConfiguration = repository.realmConfiguration

        loadInitialProgress()
        observeProgressChanges()
        
    }

    func updateTotalQuestions(_ count: Int) {
        guard count != totalQuestions else { return }
        totalQuestions = count
        recalculateProgressRate()
    }

    func refresh() {
        loadInitialProgress()
    }

    private func loadInitialProgress() {
        correctCount = repository.countCorrectAnswers(for: chapterNumericId)
        recalculateProgressRate()
    }

    private func observeProgressChanges() {
        do {
            let realm = try Realm(configuration: realmConfiguration)
            let results = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d", chapterNumericId)
            progressResults = results

            progressToken = results.observe { [weak self] changes in
                guard let self else { return }
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let correct = collection
                        .filter("statusRaw == %@", QuestionStatus.correct.rawValue)
                        .count
                    if correct != self.correctCount {
                        self.correctCount = correct
                        self.recalculateProgressRate()
                    } else if self.totalQuestions == 0 {
                        self.recalculateProgressRate()
                    }
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }
        } catch {
            print("❌ Realm observe failed: \(error)")
        }
    }

    private func recalculateProgressRate() {
        guard totalQuestions > 0 else {
            progressRate = 0
            return
        }

        progressRate = min(max(Double(correctCount) / Double(totalQuestions), 0), 1)
    }

    deinit {
        progressToken?.invalidate()
    }
}
