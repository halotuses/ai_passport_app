import Foundation
import RealmSwift

enum QuestionStatus: String, CaseIterable, Sendable {
    case unanswered
    case correct
    case incorrect

    var isAnswered: Bool { self != .unanswered }
}

final class QuestionProgressObject: Object {
    @Persisted(primaryKey: true) var quizId: String
    @Persisted var chapterId: Int
    @Persisted var statusRaw: String = QuestionStatus.unanswered.rawValue
    @Persisted var updatedAt: Date = Date()

    var status: QuestionStatus {
        get { QuestionStatus(rawValue: statusRaw) ?? .unanswered }
        set { statusRaw = newValue.rawValue }
    }
}
