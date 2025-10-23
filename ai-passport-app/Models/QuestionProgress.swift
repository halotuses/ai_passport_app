import Foundation

/// 問題ごとの学習進捗を保持する構造体
struct QuestionProgress: Identifiable, Sendable {


    var id: String { quizId }
    let quizId: String
    let chapterId: Int
    var status: QuestionStatus
    var updatedAt: Date
    var unitId: String
    var chapterIdentifier: String
    var selectedAnswerIndex: Int?
    var correctAnswerIndex: Int?
    var questionText: String?
    var choiceTexts: [String]

    init(
        quizId: String,
        chapterId: Int,
        status: QuestionStatus,
        updatedAt: Date = Date(),
        unitId: String = "",
        chapterIdentifier: String = "",
        selectedAnswerIndex: Int? = nil,
        correctAnswerIndex: Int? = nil,
        questionText: String? = nil,
        choiceTexts: [String] = []
    ) {
        self.quizId = quizId
        self.chapterId = chapterId
        self.status = status
        self.updatedAt = updatedAt
        self.unitId = unitId
        self.chapterIdentifier = chapterIdentifier
        self.selectedAnswerIndex = selectedAnswerIndex
        self.correctAnswerIndex = correctAnswerIndex
        self.questionText = questionText
        self.choiceTexts = choiceTexts
    }

    init(object: QuestionProgressObject) {
        self.quizId = object.quizId
        self.chapterId = object.chapterId
        self.status = object.status
        self.updatedAt = object.updatedAt
        self.unitId = object.unitIdentifier
        self.chapterIdentifier = object.chapterIdentifier
        self.selectedAnswerIndex = object.selectedChoiceIndex
        self.correctAnswerIndex = object.correctChoiceIndex
        self.questionText = object.questionText
        self.choiceTexts = Array(object.choiceTexts)
    }
}

extension QuestionProgress {
    /// 正解かどうかを返す
    var isCorrect: Bool { status == .correct }
    
    /// 回答済みかどうか
    var isAnswered: Bool { status.isAnswered }

    /// 選択した選択肢のテキスト
    var selectedChoiceText: String? {
        guard let index = selectedAnswerIndex, choiceTexts.indices.contains(index) else { return nil }
        return choiceTexts[index]
    }

    /// 正解の選択肢のテキスト
    var correctChoiceText: String? {
        guard let index = correctAnswerIndex, choiceTexts.indices.contains(index) else { return nil }
        return choiceTexts[index]
    }

    /// 表示用の設問位置
    var displayLocation: String {
        switch (unitId.isEmpty, chapterIdentifier.isEmpty) {
        case (false, false):
            return "\(unitId) / \(chapterIdentifier)"
        case (false, true):
            return unitId
        case (true, false):
            return chapterIdentifier
        case (true, true):
            return quizId
        }
    }
}
