//
//  QuizViewModel.swift
//  ai-passport-app
//

import Foundation

@MainActor
class QuizViewModel: ObservableObject {
    
    // MARK: - Published States
    @Published var quizzes: [Quiz] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var selectedAnswerIndex: Int? = nil
    @Published var selectedAnswers: [Int?] = []
    @Published var isLoaded: Bool = false
    @Published var hasError: Bool = false
    @Published var showResultView: Bool = false   // ✅ 結果画面表示フラグを追加
    
    // MARK: - Identifiers
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
        showResultView = false
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
            
            if let qs = result?.questions, !qs.isEmpty {
                self.quizzes = qs
                self.selectedAnswers = Array(repeating: nil, count: qs.count)
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = false
                
            } else {
                self.quizzes = []
                self.selectedAnswers = []
                self.currentQuestionIndex = 0
                self.selectedAnswerIndex = nil
                self.isLoaded = true
                self.hasError = true
                
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
        
        repository.saveOrUpdateAnswer(
            quizId: stableQuizId,
            chapterId: chapterIdInt,
            isCorrect: isCorrect
        )
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
        currentQuestionIndex = quizzes.count
        selectedAnswerIndex = nil
        showResultView = true
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
    }
}
