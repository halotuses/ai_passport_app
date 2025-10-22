import Foundation

/// 問題ごとの学習進捗を保持する構造体
struct QuestionProgress: Identifiable, Sendable {
    enum Status: String, Sendable {
        case correct
        case incorrect

        init(questionStatus: QuestionStatus) {
            switch questionStatus {
            case .correct: self = .correct
            case .incorrect, .unanswered: self = .incorrect
            }
        }

        var questionStatus: QuestionStatus {
            switch self {
            case .correct: return .correct
            case .incorrect: return .incorrect
            }
        }
    }

    var id: String { quizId }
    let quizId: String
    let chapterId: Int
    var status: Status
    var updatedAt: Date

    init(quizId: String, chapterId: Int, status: Status, updatedAt: Date = Date()) {
        self.quizId = quizId
        self.chapterId = chapterId
        self.status = status
        self.updatedAt = updatedAt
    }

    init(object: QuestionProgressObject) {
        self.quizId = object.quizId
        self.chapterId = object.chapterId
        self.status = Status(questionStatus: object.status)
        self.updatedAt = object.updatedAt
    }
}

extension QuestionProgress {
    /// 正解かどうかを返す
    var isCorrect: Bool { status == .correct }
}
