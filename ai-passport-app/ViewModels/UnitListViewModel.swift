import Foundation

@MainActor
final class UnitListViewModel: ObservableObject {
    
    @Published private(set) var metadata: QuizMetadataMap?
    @Published private(set) var quizCounts: [String: Int] = [:]
    @Published private(set) var answeredCounts: [String: Int] = [:]
    @Published private(set) var isLoading = false
    
    private let repository: RealmAnswerHistoryRepository
    private var hasLoadedOnce = false
    private var answerHistoryObserver: NSObjectProtocol?

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository
        answerHistoryObserver = NotificationCenter.default.addObserver(
            forName: .answerHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAnsweredCounts()
        }
    }

    deinit {
        if let observer = answerHistoryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func fetchMetadata() {
        guard !isLoading else { return }
        isLoading = true
        
        NetworkManager.fetchMetadata { [weak self] result in
            guard let self else { return }
            self.metadata = result
            self.quizCounts = Self.buildInitialQuizCounts(from: result)
            self.refreshAnsweredCounts(for: result)
            self.isLoading = false
            self.hasLoadedOnce = (result != nil)
            self.loadQuizCounts(from: result)
        }
    }
    
    func refreshIfNeeded() {
        if !hasLoadedOnce {
            fetchMetadata()
        }
    }
    
    // ✅ staticメソッド内ではインスタンスメンバーを使わない
    private static func buildInitialQuizCounts(from metadata: QuizMetadataMap?) -> [String: Int] {
        guard let metadata else { return [:] }
        var counts: [String: Int] = [:]
        for (key, value) in metadata {
            counts[key] = value.total
        }
        return counts
    }

    // ✅ クラス直下に配置してスコープを正す
    private func refreshAnsweredCounts(for metadata: QuizMetadataMap? = nil) {
        guard let metadata = metadata ?? self.metadata else {
            answeredCounts = [:]
            return
        }

        var counts: [String: Int] = [:]
        for key in metadata.keys {
            counts[key] = repository.answeredCount(unitId: key)
        }
        answeredCounts = counts
    }

    private func loadQuizCounts(from metadata: QuizMetadataMap?) {
        guard let metadata else { return }
        
        let unitGroup = DispatchGroup()
        var counts: [String: Int] = Self.buildInitialQuizCounts(from: metadata)
        
        for (key, unit) in metadata {
            unitGroup.enter()
            let chapterListURL = Constants.url(unit.file)
            
            NetworkManager.fetchChapterList(from: chapterListURL) { chapterList in
                guard let chapters = chapterList?.chapters, !chapters.isEmpty else {
                    unitGroup.leave()
                    return
                }
                
                var total = 0
                let chapterGroup = DispatchGroup()
                
                for chapter in chapters {
                    chapterGroup.enter()
                    let quizURL = Constants.url(chapter.file)
                    
                    NetworkManager.fetchQuizList(from: quizURL) { quizList in
                        total += quizList?.questions.count ?? 0
                        chapterGroup.leave()
                    }
                }
                
                chapterGroup.notify(queue: .main) {
                    counts[key] = total
                    unitGroup.leave()
                }
            }
        }
        
        unitGroup.notify(queue: .main) { [weak self] in
            self?.quizCounts = counts
        }
    }
}
