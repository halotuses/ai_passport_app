import Foundation

@MainActor
final class CorrectAnswerPlayViewModel: ObservableObject {
    @Published private(set) var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    private(set) var isLoaded: Bool = false

    let chapter: CorrectAnswerView.ChapterEntry

    init(chapter: CorrectAnswerView.ChapterEntry) {
        self.chapter = chapter
    }

    var currentQuiz: Quiz? {
        guard quizzes.indices.contains(currentQuestionIndex) else { return nil }
        return quizzes[currentQuestionIndex]
    }

    var totalCount: Int { quizzes.count }

    var hasNextQuestion: Bool {
        (currentQuestionIndex + 1) < quizzes.count
    }

    func loadIfNeeded() {
        guard !isLoaded else { return }
        loadQuizzes()
    }

    func reload() {
        loadQuizzes()
    }

    func selectAnswer(_ index: Int) {
        selectedAnswerIndex = index
    }

    @discardableResult
    func advanceToNextQuestion() -> Bool {
        guard !quizzes.isEmpty else { return false }
        if currentQuestionIndex < quizzes.count - 1 {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
            return true
        } else {
            selectedAnswerIndex = nil
            return false
        }
    }

    private func loadQuizzes() {
        isLoading = true
        hasError = false
        isLoaded = false
        currentQuestionIndex = 0
        selectedAnswerIndex = nil

        let normalizedPath = normalizedFilePath(chapter.chapter.file)
        let url = Constants.url(normalizedPath)

        NetworkManager.fetchQuizList(from: url) { [weak self] response in
            guard let self else { return }
            let quizzes = self.makeQuizzes(from: response)
            self.quizzes = quizzes
            self.isLoading = false
            self.hasError = quizzes.isEmpty
            self.isLoaded = true
        }
    }

    private func makeQuizzes(from response: QuizList?) -> [Quiz] {
        let fetchedQuizzes = response?.questions ?? []

        return chapter.questions.compactMap { entry in
            if fetchedQuizzes.indices.contains(entry.questionIndex) {
                return fetchedQuizzes[entry.questionIndex]
            }
            return fallbackQuiz(from: entry)
        }
    }

    private func fallbackQuiz(from entry: CorrectAnswerView.ChapterEntry.QuestionEntry) -> Quiz? {
        let progress = entry.progress
        let questionText: String
        if let stored = progress.questionText, !stored.isEmpty {
            questionText = stored
        } else {
            questionText = entry.questionText
        }

        let choices = progress.choiceTexts
        guard !choices.isEmpty else { return nil }

        let resolvedAnswerIndex: Int
        if let index = progress.correctAnswerIndex, choices.indices.contains(index) {
            resolvedAnswerIndex = index
        } else if let selected = progress.selectedAnswerIndex, choices.indices.contains(selected) {
            resolvedAnswerIndex = selected
        } else {
            resolvedAnswerIndex = 0
        }

        return Quiz(
            question: questionText,
            choices: choices,
            answerIndex: resolvedAnswerIndex,
            explanation: nil
        )
    }

    private func normalizedFilePath(_ original: String) -> String {
        var path = original
        if path.hasPrefix("/") {
            path.removeFirst()
        }
        if !path.hasPrefix("quizzes/") {
            path = "quizzes/" + path
        }
        return path
    }
}
