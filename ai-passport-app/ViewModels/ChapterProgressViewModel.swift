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
    private let chapterNumericId: Int
    private var progressToken: NotificationToken?
    private var answerHistoryObserver: NSObjectProtocol?

    init(
        unitId: String,
        chapter: ChapterMetadata,
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()
    ) {
        self.chapter = chapter
        self.repository = repository
        self.id = chapter.id
        self.chapterNumericId = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapter.id)

        loadInitialProgress()
        observeProgressChanges()
        
        answerHistoryObserver = NotificationCenter.default.addObserver(
            forName: .answerHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // 即時反映対応: 通知受信時に強制再計算
            self?.refresh()
        }
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
        progressToken = repository.observeChapterProgress(for: chapterNumericId) { [weak self] progresses in
            guard let self else { return }
            let correct = progresses.filter(\.isCorrect).count
            if correct != self.correctCount {
                self.correctCount = correct
                self.recalculateProgressRate()
            } else if self.totalQuestions == 0 {
                self.recalculateProgressRate()
            }
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
        if let answerHistoryObserver {
            NotificationCenter.default.removeObserver(answerHistoryObserver)
        }
    }
}
