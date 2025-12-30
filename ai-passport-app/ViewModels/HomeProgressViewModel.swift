import Foundation
@preconcurrency import RealmSwift

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
    private let realmManager: RealmManager
    private var hasLoadedMetadata = false
    private var progressToken: NotificationToken?
    private var progressResults: Results<QuestionProgressObject>?

    init(
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository(),
        realmManager: RealmManager = .shared
    ) {
        self.repository = repository
        self.realmConfiguration = repository.realmConfiguration
        self.realmManager = realmManager

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
        guard !hasLoadedMetadata, !isLoading else { return }

        isLoading = true
        NetworkManager.fetchMetadata { [weak self] metadata in
            guard let self else { return }
            
            guard let metadata else {
                self.isLoading = false
                return
            }

            self.loadTotalQuestionCount(from: metadata)
        }
    }

    private func loadTotalQuestionCount(from metadata: QuizMetadataMap) {
        let fallbackTotal = metadata.values.reduce(0) { $0 + $1.total }
        applyTotalQuestionCount(fallbackTotal)

        guard !metadata.isEmpty else {
            isLoading = false
            hasLoadedMetadata = true
            return
        }

        let unitGroup = DispatchGroup()
        var aggregatedTotal = 0

        for (_, unit) in metadata {
            unitGroup.enter()
            let chapterListURL = Constants.url(unit.file)

            NetworkManager.fetchChapterList(from: chapterListURL) { chapterList in
                guard let chapters = chapterList?.chapters, !chapters.isEmpty else {
                    unitGroup.leave()
                    return
                }

                var unitTotal = 0
                let chapterGroup = DispatchGroup()

                for chapter in chapters {
                    chapterGroup.enter()
                    let quizURL = Constants.url(chapter.file)

                    NetworkManager.fetchQuizList(from: quizURL) { quizList in
                        unitTotal += quizList?.questions.count ?? 0
                        chapterGroup.leave()
                    }
                }

                chapterGroup.notify(queue: .main) {
                    aggregatedTotal += unitTotal
                    unitGroup.leave()
                }
            }
        }

        unitGroup.notify(queue: .main) { [weak self] in
            guard let self else { return }

            if aggregatedTotal > 0 {
                self.applyTotalQuestionCount(aggregatedTotal)
                self.hasLoadedMetadata = true
            } else if fallbackTotal == 0 {
                self.hasLoadedMetadata = true
            }

            self.isLoading = false

        }
    }

    private func applyTotalQuestionCount(_ candidate: Int) {
        let resolvedTotal = max(candidate, totalAnswered)
        totalQuestions = resolvedTotal
        updateCompletionRate()
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
            let realm = try realmManager.realm(configuration: realmConfiguration)
            let results = realm.objects(QuestionProgressObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: false)
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
        if totalQuestions < answered {
            totalQuestions = answered
        }
        updateCompletionRate()
    }
    deinit {
        progressToken?.invalidate()
    }
}
