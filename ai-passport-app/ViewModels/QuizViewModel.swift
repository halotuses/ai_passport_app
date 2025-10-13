// ViewModels/QuizViewModel.swift
import Foundation

@MainActor
class QuizViewModel: ObservableObject {

    @Published var quizzes: [Quiz] = []
    @Published var currentIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var selectedAnswers: [Int?] = []
    @Published var isLoaded: Bool = false
    @Published var hasError: Bool = false

    var unitId: String = ""
    var chapterId: String = ""

    private let repository = AnswerHistoryRepository()

    // MARK: - Load
    func fetchQuizzes(from chapterFilePath: String) {
        // いったん初期化
        isLoaded = false
        hasError = false
        quizzes = []
        currentIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = []

        let fullURL = Constants.url(chapterFilePath)
        NetworkManager.fetchQuizList(from: fullURL) { [weak self] result in
            guard let self else { return }
            if let qs = result?.questions, !qs.isEmpty {
                self.quizzes = qs
                self.selectedAnswers = Array(repeating: nil, count: qs.count)
                self.currentIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = false
            } else {
                // データなし or 失敗
                self.quizzes = []
                
                print("✅ loaded quizzes:", self.quizzes.count)
                self.selectedAnswers = []
                self.currentIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true          // ロードは完了
                self.hasError = true          // ただし中身は空
            }
        }
    }

    // MARK: - Answer
    func recordAnswer(selectedIndex: Int) {
        selectedAnswerIndex = selectedIndex

        if currentIndex < selectedAnswers.count {
            selectedAnswers[currentIndex] = selectedIndex
        } else {
            selectedAnswers.append(selectedIndex)
        }

        guard currentIndex < quizzes.count else { return }
        let quiz = quizzes[currentIndex]
        let isCorrect = (selectedIndex == quiz.answerIndex)
        let chapterIdInt = Int(chapterId) ?? 0

        // 安定キー（章ID#インデックス）
        let stableQuizId = "\(chapterId)#\(currentIndex)"

        repository.saveOrUpdateAnswer(
            quizId: stableQuizId,
            chapterId: chapterIdInt,
            isCorrect: isCorrect
        )
    }

    func moveNext() {
        currentIndex += 1
        selectedAnswerIndex = nil
    }

    // MARK: - Computed
    private var hasQuizzes: Bool { !quizzes.isEmpty }

    var isFinished: Bool {
        // 「問題が1問以上ある」かつ「最後まで到達」でのみ true
        hasQuizzes && currentIndex >= quizzes.count
    }

    var totalCount: Int { quizzes.count }

    var correctCount: Int {
        quizzes.enumerated().filter { idx, q in
            selectedAnswers.indices.contains(idx) && selectedAnswers[idx] == q.answerIndex
        }.count
    }

    var incorrectCount: Int {
        quizzes.enumerated().filter { idx, q in
            selectedAnswers.indices.contains(idx) && selectedAnswers[idx] != q.answerIndex
        }.count
    }

    var accuracy: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalCount)) * 100.0)
    }

    var currentQuiz: Quiz? {
        (currentIndex < quizzes.count) ? quizzes[currentIndex] : nil
    }

    // MARK: - Reset
    func reset() {
        currentIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = Array(repeating: nil, count: quizzes.count)
        isLoaded = !quizzes.isEmpty
        hasError = false
    }
}
