import Foundation

@MainActor
final class ReviewPlayViewModel: ObservableObject {
    @Published private(set) var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false
    private(set) var isLoaded: Bool = false

    let category: ReviewCategory
    let unit: QuizMetadata
    let chapter: ChapterMetadata

    private var orderedQuestions: [ReviewUnitListViewModel.ReviewChapter.ReviewQuestion]
    private var initialQuestionId: String?
    private var questionIndexMap: [String: Int] = [:]

    init(
        category: ReviewCategory,
        unit: QuizMetadata,
        chapter: ChapterMetadata,
        questions: [ReviewUnitListViewModel.ReviewChapter.ReviewQuestion],
        initialQuestionId: String? = nil
    ) {
        self.category = category
        self.unit = unit
        self.chapter = chapter
        self.orderedQuestions = questions
        self.initialQuestionId = initialQuestionId
    }

    var totalCount: Int { quizzes.count }

    var currentQuiz: Quiz? {
        guard quizzes.indices.contains(currentQuestionIndex) else { return nil }
        return quizzes[currentQuestionIndex]
    }

    var currentQuestion: ReviewUnitListViewModel.ReviewChapter.ReviewQuestion? {
        guard orderedQuestions.indices.contains(currentQuestionIndex) else { return nil }
        return orderedQuestions[currentQuestionIndex]
    }

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

    func removeCurrentQuestion() {
        guard orderedQuestions.indices.contains(currentQuestionIndex) else { return }

        orderedQuestions.remove(at: currentQuestionIndex)

        if quizzes.indices.contains(currentQuestionIndex) {
            quizzes.remove(at: currentQuestionIndex)
        }

        rebuildQuestionIndexMap()

        if quizzes.isEmpty {
            currentQuestionIndex = 0
            selectedAnswerIndex = nil
            hasError = false
            return
        }

        if currentQuestionIndex >= quizzes.count {
            currentQuestionIndex = max(quizzes.count - 1, 0)
        }

        selectedAnswerIndex = nil
    }

    private func loadQuizzes() {
        isLoading = true
        hasError = false
        isLoaded = false
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        questionIndexMap = [:]

        orderedQuestions.sort { lhs, rhs in
            if lhs.questionIndex == rhs.questionIndex {
                return lhs.quizId.localizedCompare(rhs.quizId) == .orderedAscending
            }
            return lhs.questionIndex < rhs.questionIndex
        }

        let normalizedPath = normalizedFilePath(chapter.file)
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

        for entry in orderedQuestions {
            let quiz: Quiz?
            if fetchedQuizzes.indices.contains(entry.questionIndex) {
                quiz = fetchedQuizzes[entry.questionIndex]
            } else {
                quiz = fallbackQuiz(from: entry)
            }

            if let quiz {
                indexMap[entry.quizId] = quizzes.count
                quizzes.append(quiz)
            }
        }

        return (quizzes, indexMap)
    }

    private func fallbackQuiz(from entry: ReviewUnitListViewModel.ReviewChapter.ReviewQuestion) -> Quiz? {
        let progress = entry.progress
        let questionText: String
        if let stored = progress.questionText, !stored.isEmpty {
            questionText = stored
        } else {
            questionText = "問題ID: \(entry.quizId)"
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

    private func rebuildQuestionIndexMap() {
        questionIndexMap = Dictionary(uniqueKeysWithValues: orderedQuestions.enumerated().map { index, question in
            (question.quizId, index)
        })
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
