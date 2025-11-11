import Foundation

@MainActor
final class BookmarkPlayViewModel: ObservableObject {
    @Published private(set) var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    private(set) var isLoaded: Bool = false

    let chapter: BookmarkUnitView.ChapterEntry
    private var initialQuestionId: String?
    private var questionIndexMap: [String: Int] = [:]

    init(
        chapter: BookmarkUnitView.ChapterEntry,
        initialQuestionId: String? = nil
    ) {
        self.chapter = chapter
        self.initialQuestionId = initialQuestionId
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
        questionIndexMap = [:]

        let normalizedPath = normalizedFilePath(chapter.chapter.file)
        let url = Constants.url(normalizedPath)

        NetworkManager.fetchQuizList(from: url) { [weak self] response in
            guard let self else { return }
            let result = self.makeQuizzes(from: response)
            self.quizzes = result.quizzes
            self.questionIndexMap = result.indexMap
            self.isLoading = false
            self.hasError = result.quizzes.isEmpty
            self.isLoaded = true
            if let initialQuestionId,
               let index = self.questionIndexMap[initialQuestionId],
               self.quizzes.indices.contains(index) {
                self.currentQuestionIndex = index
            }
            self.initialQuestionId = nil
        }
    }

    private func makeQuizzes(from response: QuizList?) -> (quizzes: [Quiz], indexMap: [String: Int]) {
        let fetchedQuizzes = response?.questions ?? []
        var quizzes: [Quiz] = []
        var indexMap: [String: Int] = [:]

        for entry in chapter.questions {
            let quiz: Quiz?
            if fetchedQuizzes.indices.contains(entry.questionIndex) {
                quiz = fetchedQuizzes[entry.questionIndex]
            } else {
                quiz = fallbackQuiz(from: entry)
            }

            if let quiz {
                indexMap[entry.id] = quizzes.count
                quizzes.append(quiz)
            }
        }

        return (quizzes, indexMap)
    }

    private func fallbackQuiz(from entry: BookmarkUnitView.ChapterEntry.QuestionEntry) -> Quiz? {
        let progress = entry.progress
        let questionText: String
        if let text = progress?.questionText, !text.isEmpty {
            questionText = text
        } else if !entry.item.questionText.isEmpty {
            questionText = entry.item.questionText
        } else {
            questionText = "問題ID: \(entry.quizId)"
        }

        let choices: [String]
        if let storedChoices = progress?.choiceTexts, !storedChoices.isEmpty {
            choices = storedChoices
        } else {
            return nil
        }

        let resolvedAnswerIndex: Int
        if let index = progress?.correctAnswerIndex, choices.indices.contains(index) {
            resolvedAnswerIndex = index
        } else if let selected = progress?.selectedAnswerIndex, choices.indices.contains(selected) {
            resolvedAnswerIndex = selected
        } else {
            resolvedAnswerIndex = 0
        }

        return Quiz(
            orderRef: entry.quizId,
            question: questionText,
            choices: choices,
            answerIndex: resolvedAnswerIndex,
            explanation: nil
        )
    }

    private func normalizedFilePath(_ original: String) -> String {
        var path = original.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.lowercased().hasPrefix("http") {
            return path
        }
        if path.hasPrefix("/") {
            path.removeFirst()
        }
        if !path.hasPrefix("quizzes/") {
            path = "quizzes/" + path
        }
        return path
    }
}
