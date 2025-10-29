import Foundation
import RealmSwift

final class BookmarkObject: Object, Identifiable {
    @Persisted(primaryKey: true) var quizId: String
    @Persisted var userId: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
    @Persisted var isBookmarked: Bool = true
    @Persisted var questionText: String = ""

    var id: String { quizId }
}
