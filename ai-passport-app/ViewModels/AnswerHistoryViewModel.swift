import Foundation
import RealmSwift

@MainActor
final class AnswerHistoryViewModel: ObservableObject {
    @Published private(set) var histories: [QuestionProgress] = []
    @Published private(set) var isLoading: Bool = true

    private let repository: RealmAnswerHistoryRepository
    private var token: NotificationToken?

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository
        loadInitialHistory()
        observeHistory()
    }

    func refresh() {
        loadInitialHistory()
    }

    deinit {
        token?.invalidate()
    }

    private func loadInitialHistory() {
        histories = repository.fetchAnswerHistory()
        isLoading = false
    }

    private func observeHistory() {
        token = repository.observeAnswerHistory { [weak self] progresses in
            guard let self else { return }
            self.histories = progresses
            self.isLoading = false
        }
    }
}
