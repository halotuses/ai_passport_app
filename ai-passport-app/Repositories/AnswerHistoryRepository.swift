import CoreData

class AnswerHistoryRepository {
    private let viewContext = PersistenceController.shared.container.viewContext

    func saveOrUpdateAnswer(quizId: String, chapterId: Int, isCorrect: Bool) {
        let request: NSFetchRequest<AnswerHistory> = AnswerHistory.fetchRequest()
        request.predicate = NSPredicate(format: "quizId == %@", quizId)

        do {
            let results = try viewContext.fetch(request)
            let entry = results.first ?? AnswerHistory(context: viewContext)

            entry.quizId = quizId
            entry.chapterId = Int32(chapterId)
            entry.isCorrect = isCorrect
            entry.answeredAt = Date()

            try viewContext.save()
        } catch {
            print("❌ 保存失敗: \(error)")
        }
    }

    func countCorrectAnswers(for chapterId: Int) -> Int {
        let request: NSFetchRequest<AnswerHistory> = AnswerHistory.fetchRequest()
        request.predicate = NSPredicate(format: "chapterId == %d AND isCorrect == true", chapterId)

        do {
            return try viewContext.count(for: request)
        } catch {
            print("❌ カウント取得失敗: \(error)")
            return 0
        }
    }

    func deleteAllHistory() {
        let request: NSFetchRequest<NSFetchRequestResult> = AnswerHistory.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try viewContext.execute(deleteRequest)
            try viewContext.save()
        } catch {
            print("❌ 全削除失敗: \(error)")
        }
    }
}
