import Foundation
import RealmSwift

@MainActor
final class HomeProgressViewModel: ObservableObject {
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var totalCorrect: Int = 0
    @Published private(set) var totalIncorrect: Int = 0
    @Published private(set) var totalAnswered: Int = 0
    @Published private(set) var completionRate: Double = 0
    @Published private(set) var isLoading: Bool = false

    private let repository: RealmAnswerHistoryRepository
    private let realmConfiguration: Realm.Configuration
    private var hasLoadedMetadata = false
    private var progressToken: NotificationToken?
    private var progressResults: Results<QuestionProgressObject>?

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository
        self.realmConfiguration = repository.realmConfiguration

        observeAllProgress()
    }

    func refresh() {
        reloadProgress()
        fetchMetadataIfNeeded()
    }

    func reloadProgress() {
        let correct = repository.totalCorrectAnswerCount()
        let incorrect = repository.totalIncorrectAnswerCount()
        let answered = repository.totalAnsweredCount()
        updateAggregates(correct: correct, incorrect: incorrect, answered: answered)
    }

    var totalUnanswered: Int {
        max(totalQuestions - totalAnswered, 0)
    }

    private func fetchMetadataIfNeeded() {
        guard !hasLoadedMetadata else { return }

        isLoading = true
        NetworkManager.fetchMetadata { [weak self] metadata in
            guard let self else { return }

            self.isLoading = false
            self.hasLoadedMetadata = (metadata != nil)
            self.totalQuestions = metadata?.values.reduce(0) { $0 + $1.total } ?? 0
            self.updateCompletionRate()
        }
    }

    private func updateCompletionRate() {
        guard totalQuestions > 0 else {
            completionRate = 0
            return
        }

        completionRate = min(max(Double(totalCorrect) / Double(totalQuestions), 0), 1)
    }

    private func observeAllProgress() {
        do {
            let realm = try Realm(configuration: realmConfiguration)
            let results = realm.objects(QuestionProgressObject.self)
            progressResults = results

            progressToken = results.observe { [weak self] changes in
                guard let self else { return }
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let correct = collection.filter("statusRaw == %@", QuestionStatus.correct.rawValue).count
                    let incorrect = collection.filter("statusRaw == %@", QuestionStatus.incorrect.rawValue).count
                    let answered = collection.filter("statusRaw != %@", QuestionStatus.unanswered.rawValue).count
                    self.updateAggregates(correct: correct, incorrect: incorrect, answered: answered)
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }
        } catch {
            print("❌ Realm observe failed: \(error)")
        }
    }

    private func updateAggregates(correct: Int, incorrect: Int, answered: Int) {
        totalCorrect = correct
        totalIncorrect = incorrect
        totalAnswered = answered
        updateCompletionRate()
    }

    deinit {
        progressToken?.invalidate()
    }
}
