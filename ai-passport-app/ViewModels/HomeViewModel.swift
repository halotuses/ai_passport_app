import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var daysUntilExam: Int? = nil
    @Published private(set) var encouragementMessage: String = ""

    @Published private(set) var examDate: Date

    let progressViewModel: HomeProgressViewModel

    private var cancellables: Set<AnyCancellable> = []
    private static let examDateStorageKey = "home.examDate"

    init(
        currentDate: Date = Date(),
        progressViewModel: HomeProgressViewModel? = nil
    ) {

        self.progressViewModel = progressViewModel ?? HomeProgressViewModel()
        if let storedDate = Self.storedExamDate() {
            examDate = storedDate
        } else if let defaultDate = Calendar.current.date(byAdding: .day, value: 90, to: currentDate) {
            examDate = defaultDate
        } else {
            examDate = currentDate
        }

        refreshCountdown(from: currentDate)
        
        bindProgressUpdates(currentDate: currentDate)
    }

    func refresh(currentDate: Date = Date()) {
        progressViewModel.refresh()
        refreshCountdown(from: currentDate)
    }

    func reloadProgress(currentDate: Date = Date()) {
        progressViewModel.reloadProgress()
        refreshCountdown(from: currentDate)
    }

    func updateExamDate(_ date: Date, currentDate: Date = Date()) {
        examDate = date
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Self.examDateStorageKey)
        refreshCountdown(from: currentDate)
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
    
    private func bindProgressUpdates(currentDate: Date) {
        progressViewModel.objectWillChange
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshCountdown(from: Date())
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    var totalQuestions: Int { progressViewModel.totalQuestions }
    var totalCorrect: Int { progressViewModel.totalCorrect }
    var totalIncorrect: Int { progressViewModel.totalIncorrect }
    var totalAnswered: Int { progressViewModel.totalAnswered }
    var completionRate: Double { progressViewModel.completionRate }
    var totalUnanswered: Int { progressViewModel.totalUnanswered }
    var isLoading: Bool { progressViewModel.isLoading }
}
