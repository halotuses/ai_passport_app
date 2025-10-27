//
//  QuizViewModel.swift
//  ai-passport-app
//

import Foundation
import RealmSwift

@MainActor
class QuizViewModel: ObservableObject {
    
    // MARK: - Published States
    @Published var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var selectedAnswers: [Int?] = []
    @Published var isLoaded: Bool = false
    @Published var hasError: Bool = false
    @Published var showResultView: Bool = false
    @Published var questionStatuses: [QuestionStatus] = []
    @Published private(set) var bookmarkedQuizIds: Set<String> = []
    
    
    // MARK: - Identifiers
    var unitId: String = ""
    var chapterId: String = ""
    
    private let repository: RealmAnswerHistoryRepository
    private let persistenceQueue = DispatchQueue(label: "com.ai-passport.quizAnswerPersistence", qos: .utility)

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository
        
    }
    
    // MARK: - Load
    func fetchQuizzes(from chapterFilePath: String) {
        isLoaded = false
        hasError = false
        quizzes = []
        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = []
        showResultView = false
        questionStatuses = []
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
        
        NetworkManager.fetchQuizList(from: fullURL) { [weak self] result in
            guard let self else { return }
            hydrateQuestionStatusesIfNeeded()
            
            if let qs = result?.questions, !qs.isEmpty {
                self.quizzes = qs
                self.selectedAnswers = Array(repeating: nil, count: qs.count)
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = false
                let chapterNumericId = IdentifierGenerator.chapterNumericId(unitId: self.unitId, chapterId: self.chapterId)
                let storedStatuses = self.repository.loadStatuses(chapterId: chapterNumericId)
                self.bookmarkedQuizIds = self.loadBookmarkedQuizIds(chapterId: chapterNumericId)
                self.questionStatuses = qs.enumerated().map { index, _ in
                    let quizId = "\(self.unitId)-\(self.chapterId)#\(index)"
                    return storedStatuses[quizId] ?? .unanswered
                }
                
            } else {
                self.quizzes = []
                self.selectedAnswers = []
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = true
                self.questionStatuses = []
                self.bookmarkedQuizIds = []
                
            }
        }
    }
    
    
    // MARK: - Answer Record
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
        let chapterIdInt = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapterId)
        let stableQuizId = "\(unitId)-\(chapterId)#\(currentQuestionIndex)"
        

        let status: QuestionStatus = isCorrect ? .correct : .incorrect
        if questionStatuses.indices.contains(currentQuestionIndex) {
            questionStatuses[currentQuestionIndex] = status
        } else {
            questionStatuses.append(status)
        }

        let repository = repository
        let currentUnitId = unitId
        let currentChapterIdentifier = chapterId
        let questionText = quiz.question
        let choiceTexts = quiz.choices
        let correctIndex = quiz.answerIndex
        let persistedAt = Date()
        persistenceQueue.async {
            autoreleasepool {
                repository.saveOrUpdateAnswerSnapshot(
                    quizId: stableQuizId,
                    chapterId: chapterIdInt,
                    unitId: currentUnitId,
                    chapterIdentifier: currentChapterIdentifier,
                    status: status,
                    selectedChoiceIndex: selectedIndex,
                    correctChoiceIndex: correctIndex,
                    questionText: questionText,
                    choiceTexts: choiceTexts,
                    updatedAt: persistedAt
                )
            }
        }
    }
    func persistAllStatusesImmediately() {
        guard !quizzes.isEmpty else { return }

        // 即時反映対応: バックグラウンド保存が残っていれば待機する
        persistenceQueue.sync { }

        let chapterIdInt = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapterId)
        for (index, status) in questionStatuses.enumerated() where status.isAnswered {
            guard quizzes.indices.contains(index) else { continue }
            let quiz = quizzes[index]
            let stableQuizId = "\(unitId)-\(chapterId)#\(index)"
            let selectedAnswer: Int?
            if selectedAnswers.indices.contains(index) {
                selectedAnswer = selectedAnswers[index]
            } else {
                selectedAnswer = nil
            }
            repository.updateAnswerStatusImmediately(
                quizId: stableQuizId,
                chapterId: chapterIdInt,
                status: status,
                selectedChoiceIndex: selectedAnswer,
                correctChoiceIndex: quiz.answerIndex,
                questionText: quiz.question,
                choiceTexts: quiz.choices,
                unitId: unitId,
                chapterIdentifier: chapterId
            )
        }
    }
    // MARK: - Bookmark
    func toggleBookmark(for quiz: Quiz) {
        guard let stableQuizId = bookmarkIdentifier(for: quiz) else { return }
        let chapterNumericId = IdentifierGenerator.chapterNumericId(unitId: unitId, chapterId: chapterId)

        do {
            let realm = try Realm()
            var newState = false
            try realm.write {
                let object: QuestionProgressObject
                if let existing = realm.object(ofType: QuestionProgressObject.self, forPrimaryKey: stableQuizId) {
                    object = existing
                } else {
                    let newObject = QuestionProgressObject()
                    newObject.quizId = stableQuizId
                    newObject.chapterId = chapterNumericId
                    realm.add(newObject)
                    object = newObject
                }

                object.unitIdentifier = unitId
                object.chapterIdentifier = chapterId
                object.questionText = quiz.question
                object.choiceTexts.removeAll()
                object.choiceTexts.append(objectsIn: quiz.choices)
                object.correctChoiceIndex = quiz.answerIndex
                object.updatedAt = Date()
                object.isBookmarked.toggle()
                newState = object.isBookmarked
            }

            if newState {
                bookmarkedQuizIds.insert(stableQuizId)
            } else {
                bookmarkedQuizIds.remove(stableQuizId)
            }
        } catch {
            print("❌ Failed to toggle bookmark: \(error)")
        }
    }

    func isBookmarked(quiz: Quiz) -> Bool {
        guard let stableQuizId = bookmarkIdentifier(for: quiz) else { return false }
        return bookmarkedQuizIds.contains(stableQuizId)
    }
    
    // MARK: - Navigation
    func moveNext() {
        guard hasQuizzes else { return }
        
        if currentQuestionIndex < quizzes.count - 1 {
            currentQuestionIndex += 1
            selectedAnswerIndex = nil
        } else {
            // ✅ 最後の問題を終えたら結果画面へ
            finishQuiz()
        }
    }
    
    func finishQuiz() {
        guard hasQuizzes else { return }
        persistAllStatusesImmediately()
        currentQuestionIndex = quizzes.count
        selectedAnswerIndex = nil
        showResultView = true
    }
    
    func restartQuiz() {
        guard hasQuizzes else { return }

        currentQuestionIndex = 0
        selectedAnswerIndex = nil
        selectedAnswers = Array(repeating: nil, count: quizzes.count)
        questionStatuses = Array(repeating: .unanswered, count: quizzes.count)
        showResultView = false
    }
    
    // MARK: - Computed
    private var hasQuizzes: Bool { !quizzes.isEmpty }
    
    var hasNextQuestion: Bool {
        hasQuizzes && (currentQuestionIndex + 1) < quizzes.count
    }
    
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
        chapterId = ""
        unitId = ""
        showResultView = false
        questionStatuses = Array(repeating: .unanswered, count: quizzes.count)
        bookmarkedQuizIds = []
    }
}

extension QuizViewModel: QuizNavigationCleanupDelegate {
    func prepareForQuizNavigationCleanup() {
        persistAllStatusesImmediately()
        reset()
    }
}

private extension QuizViewModel {
    func hydrateQuestionStatusesIfNeeded() {
        guard !quizzes.isEmpty else { return }

        if questionStatuses.count < quizzes.count {
            questionStatuses.append(contentsOf: Array(repeating: .unanswered, count: quizzes.count - questionStatuses.count))
        }

        for index in quizzes.indices {
            guard questionStatuses[index].isAnswered == false else { continue }
            guard selectedAnswers.indices.contains(index), let selected = selectedAnswers[index] else { continue }

            let quiz = quizzes[index]
            let status: QuestionStatus = (selected == quiz.answerIndex) ? .correct : .incorrect
            questionStatuses[index] = status
        }
    }
    func loadBookmarkedQuizIds(chapterId: Int) -> Set<String> {
        do {
            let realm = try Realm()
            let results = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d AND isBookmarked == true", chapterId)
            return Set(results.map { $0.quizId })
        } catch {
            print("❌ Failed to load bookmarks: \(error)")
            return []
        }
    }

    func bookmarkIdentifier(for quiz: Quiz) -> String? {
        guard let index = quizzes.firstIndex(where: { $0.id == quiz.id }) else { return nil }
        return progressIdentifier(for: index)
    }

    func progressIdentifier(for index: Int) -> String? {
        guard quizzes.indices.contains(index) else { return nil }
        return "\(unitId)-\(chapterId)#\(index)"
    }
}
