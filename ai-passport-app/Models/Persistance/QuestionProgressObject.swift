import Foundation
@preconcurrency import RealmSwift

enum QuestionStatus: String, CaseIterable, Sendable {
    case unanswered
    case correct
    case incorrect

    var isAnswered: Bool { self != .unanswered }
}

final class QuestionProgressObject: Object, Identifiable {
    @Persisted(primaryKey: true) var quizId: String
    @Persisted var chapterId: Int
    @Persisted var statusRaw: String = QuestionStatus.unanswered.rawValue
    @Persisted var updatedAt: Date = Date()
    @Persisted var unitIdentifier: String = ""
    @Persisted var chapterIdentifier: String = ""
    @Persisted var selectedChoiceIndex: Int?
    @Persisted var correctChoiceIndex: Int?
    @Persisted var questionText: String?
    @Persisted var choiceTexts = List<String>()

    var status: QuestionStatus {
        get { QuestionStatus(rawValue: statusRaw) ?? .unanswered }
        set { statusRaw = newValue.rawValue }
    }

    var id: String { quizId }
}

extension QuestionProgressObject: @unchecked Sendable {}
