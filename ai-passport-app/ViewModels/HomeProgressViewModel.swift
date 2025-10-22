import Foundation

@MainActor
final class HomeProgressViewModel: ObservableObject {
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var totalCorrect: Int = 0
    @Published private(set) var totalIncorrect: Int = 0
    @Published private(set) var totalAnswered: Int = 0
    @Published private(set) var completionRate: Double = 0
    @Published private(set) var isLoading: Bool = false

    private let repository: RealmAnswerHistoryRepository
    private var hasLoadedMetadata = false
    private var answerHistoryObserver: NSObjectProtocol?

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository

        answerHistoryObserver = NotificationCenter.default.addObserver(
            forName: .answerHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        reloadProgress()
        fetchMetadataIfNeeded()
    }

    func reloadProgress() {
        totalCorrect = repository.totalCorrectAnswerCount()
        totalIncorrect = repository.totalIncorrectAnswerCount()
        totalAnswered = repository.totalAnsweredCount()
        updateCompletionRate()
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

    deinit {
        if let answerHistoryObserver {
            NotificationCenter.default.removeObserver(answerHistoryObserver)
        }
    }
}
