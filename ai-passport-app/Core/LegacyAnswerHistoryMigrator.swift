import CoreData
import Foundation

struct LegacyAnswerHistoryMigrator {
    private let repository: RealmAnswerHistoryRepository
    private let userDefaults: UserDefaults
    private let migrationFlagKey = "migration.answerHistory.realm.completed"

    init(
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository(),
        userDefaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.userDefaults = userDefaults
    }

    func migrateIfNeeded(currentDate: Date = Date()) {
        guard !userDefaults.bool(forKey: migrationFlagKey) else { return }

        let persistenceController = PersistenceController(resetStore: false)
        let context = persistenceController.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "AnswerHistory")

        var fetchError: Error?
        var records: [NSManagedObject] = []
        context.performAndWait {
            do {
                records = try context.fetch(request)
            } catch {
                fetchError = error
            }
        }

        if let fetchError {
            print("❌ Legacy migration fetch failed: \(fetchError)")
            return
        }

        guard !records.isEmpty else {
            finalizeMigration()
            return
        }

        for record in records {
            guard let quizId = record.value(forKey: "quizId") as? String else { continue }
            let chapterValue = (record.value(forKey: "chapterId") as? NSNumber)?.intValue
            let isCorrect = record.value(forKey: "isCorrect") as? Bool ?? false
            let answeredAt = record.value(forKey: "answeredAt") as? Date ?? currentDate

            let status: QuestionStatus = isCorrect ? .correct : .incorrect
            let resolvedChapterId = chapterValue ?? IdentifierGenerator.chapterNumericId(fromQuizIdentifier: quizId) ?? 0
            repository.saveOrUpdateStatus(
                quizId: quizId,
                chapterId: resolvedChapterId,
                status: status,
                updatedAt: answeredAt
            )
        }

        finalizeMigration()
    }

    private func finalizeMigration() {
        userDefaults.set(true, forKey: migrationFlagKey)
        _ = PersistenceController(resetStore: true)
    }
}
