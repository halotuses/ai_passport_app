import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var totalQuestions: Int = 0
    @Published private(set) var totalCorrect: Int = 0
    @Published private(set) var totalIncorrect: Int = 0
    @Published private(set) var totalAnswered: Int = 0
    @Published private(set) var completionRate: Double = 0
    @Published private(set) var daysUntilExam: Int? = nil
    @Published private(set) var encouragementMessage: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var examDate: Date

    private let repository: RealmAnswerHistoryRepository
    private var hasLoadedMetadata = false
    private var answerHistoryObserver: NSObjectProtocol?

    private static let examDateStorageKey = "home.examDate"

    init(
        currentDate: Date = Date(),
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()
    ) {
        self.repository = repository
        if let storedDate = Self.storedExamDate() {
            examDate = storedDate
        } else if let defaultDate = Calendar.current.date(byAdding: .day, value: 90, to: currentDate) {
            examDate = defaultDate
        } else {
            examDate = currentDate
        }

        refreshCountdown(from: currentDate)
        
        answerHistoryObserver = NotificationCenter.default.addObserver(
            forName: .answerHistoryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadProgress()
        }
    }

    func refresh(currentDate: Date = Date()) {
        reloadProgress(currentDate: currentDate)

        if hasLoadedMetadata {
            updateCompletionRate()
            refreshCountdown(from: currentDate)
            return
        }

        fetchMetadata(currentDate: currentDate)
    }

    func reloadProgress(currentDate: Date = Date()) {
        totalCorrect = repository.totalCorrectAnswerCount()
        totalIncorrect = repository.totalIncorrectAnswerCount()
        totalAnswered = repository.totalAnsweredCount()
        if hasLoadedMetadata {
            updateCompletionRate()
            refreshCountdown(from: currentDate)
        }
    }

    func updateExamDate(_ date: Date, currentDate: Date = Date()) {
        examDate = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.examDateStorageKey)
        refreshCountdown(from: currentDate)
    }

    private func fetchMetadata(currentDate: Date) {
        guard !isLoading else { return }

        isLoading = true
        NetworkManager.fetchMetadata { [weak self] metadata in
            guard let self else { return }

            self.isLoading = false
            self.hasLoadedMetadata = (metadata != nil)
            self.totalQuestions = metadata?.values.reduce(0) { $0 + $1.total } ?? 0
            self.updateCompletionRate()
            self.refreshCountdown(from: currentDate)
        }
    }

    private func updateCompletionRate() {
        guard totalQuestions > 0 else {
            completionRate = 0
            return
        }

        completionRate = min(max(Double(totalCorrect) / Double(totalQuestions), 0), 1)
    }

    var totalUnanswered: Int {
        max(totalQuestions - totalAnswered, 0)
    }

    
    private func refreshCountdown(from currentDate: Date) {
        let components = Calendar.current.dateComponents([.day], from: currentDate, to: examDate)
        daysUntilExam = components.day
        encouragementMessage = Self.encouragement(for: daysUntilExam, completionRate: completionRate)
    }

    private static func storedExamDate() -> Date? {
        let storedValue = UserDefaults.standard.double(forKey: examDateStorageKey)
        guard storedValue > 0 else { return nil }
        return Date(timeIntervalSince1970: storedValue)
    }

    private static func encouragement(for daysUntilExam: Int?, completionRate: Double) -> String {
        guard let daysUntilExam else {
            return "今日もコツコツ頑張ろう！"
        }

        switch daysUntilExam {
        case ..<0:
            return "試験お疲れさま！振り返りでさらに力を伸ばそう🐾"
        case 0:
            return "試験は今日！深呼吸して実力を出し切ろう✨"
        case 1...3:
            if completionRate > 0.7 {
                return "準備はばっちり！最後の仕上げも応援してるよ🔥"
            } else {
                return "あと少し！集中モードで駆け抜けよう💨"
            }
        case 4...14:
            if completionRate > 0.6 {
                return "順調なペース！この調子で積み上げよう📈"
            } else {
                return "まだ間に合うよ。一緒に計画的に進めよう📅"
            }
        default:
            if completionRate > 0.5 {
                return "着実にステップアップ中！今日も1問解いてみよう🐾"
            } else {
                return "一緒にスタート！小さな一歩から始めよう🌱"
            }
        }
    }
    
    deinit {
        if let answerHistoryObserver {
            NotificationCenter.default.removeObserver(answerHistoryObserver)
        }
    }
}
