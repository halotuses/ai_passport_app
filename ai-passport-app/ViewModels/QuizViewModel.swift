//
//  QuizViewModel.swift
//  ai-passport-app
//

import Foundation

@MainActor
class QuizViewModel: ObservableObject {

    @Published var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var selectedAnswers: [Int?] = []
    @Published var isLoaded: Bool = false
    @Published var hasError: Bool = false
    @Published var isSubmitted: Bool = false

    var unitId: String = ""
    var chapterId: String = ""

    private let repository = AnswerHistoryRepository()

    // MARK: - Load
    func fetchQuizzes(from chapterFilePath: String) {
        isLoaded = false
        hasError = false
        quizzes = []
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = []

        // ✅ URL生成ロジックを安全化
        var normalizedPath = chapterFilePath
        if normalizedPath.hasPrefix("/") {
            normalizedPath.removeFirst()
        }
        // ✅ “quizzes/” の二重付与を防止
        if !normalizedPath.hasPrefix("quizzes/") {
            normalizedPath = "quizzes/" + normalizedPath
        }

        let fullURL = Constants.url(normalizedPath)
        print("📡 fetchQuizzes called with path: \(chapterFilePath)")
        print("🌐 fullURL resolved as: \(fullURL)")

        NetworkManager.fetchQuizList(from: fullURL) { [weak self] result in
            guard let self else { return }

            if let qs = result?.questions, !qs.isEmpty {
                self.quizzes = qs
                self.selectedAnswers = Array(repeating: nil, count: qs.count)
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = false
                print("✅ Loaded \(qs.count) quizzes successfully.")
            } else {
                self.quizzes = []
                self.selectedAnswers = []
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = true
                print("⚠️ Failed to load quizzes or quiz list is empty.")
            }
        }
    }

    // MARK: - Answer
    func selectAnswer(index: Int) {
        selectedAnswerIndex = index
    }

    func submitAnswer() {
        guard currentQuestionIndex < quizzes.count else { return }
        isSubmitted = true
    }

    func recordAnswer(selectedIndex: Int) {
        selectedAnswerIndex = selectedIndex

        if currentQuestionIndex < selectedAnswers.count {
            selectedAnswers[currentQuestionIndex] = selectedIndex
        } else {
            selectedAnswers.append(selectedIndex)
        }

        guard currentQuestionIndex < quizzes.count else { return }
        let quiz = quizzes[currentQuestionIndex]
        let isCorrect = (selectedIndex == quiz.answerIndex)
        let chapterIdInt = Int(chapterId) ?? 0
        let stableQuizId = "\(chapterId)#\(currentQuestionIndex)"

        repository.saveOrUpdateAnswer(
            quizId: stableQuizId,
            chapterId: chapterIdInt,
            isCorrect: isCorrect
        )
    }

    func moveNext() {
        currentQuestionIndex += 1
        selectedAnswerIndex = nil
        isSubmitted = false
    }

    // MARK: - Computed
    private var hasQuizzes: Bool { !quizzes.isEmpty }

    var isFinished: Bool {
        hasQuizzes && currentQuestionIndex >= quizzes.count
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
        (currentQuestionIndex < quizzes.count) ? quizzes[currentQuestionIndex] : nil
    }

    // MARK: - Reset
    func reset() {
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = Array(repeating: nil, count: quizzes.count)
        isLoaded = !quizzes.isEmpty
        hasError = false
        isSubmitted = false
    }
}
