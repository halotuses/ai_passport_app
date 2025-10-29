import Foundation
import RealmSwift

enum IdentifierGenerator {
    static func chapterNumericId(unitId: String, chapterId: String) -> Int {
        let unitNumber = numericPart(from: unitId)
        let chapterNumber = numericPart(from: chapterId)
        return unitNumber * 1_000 + chapterNumber
    }
    
    static func chapterNumericId(fromQuizIdentifier quizId: String) -> Int? {
        let components = quizId.split(separator: "#")
        guard let identifiers = components.first else { return nil }
        let pair = identifiers.split(separator: "-")
        guard pair.count >= 2 else { return nil }
        return chapterNumericId(unitId: String(pair[0]), chapterId: String(pair[1]))
    }
    
    private static func numericPart(from identifier: String) -> Int {
        let digits = identifier.compactMap { $0.wholeNumberValue }
        guard !digits.isEmpty else { return 0 }
        return digits.reduce(0) { $0 * 10 + $1 }
    }
}

struct ProgressChapterIdentifier: Hashable {
    let unitId: String
    let chapterId: String

    init(unitId: String, chapterId: String) {
        self.unitId = unitId
        self.chapterId = chapterId
    }
}


final class RealmAnswerHistoryRepository {
    private let configuration: Realm.Configuration
    private let realmManager: RealmManager
    
    init(
        configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration,
        fileManager: FileManager = .default,
        realmManager: RealmManager = .shared
    ) {
        self.configuration = configuration
        self.realmManager = realmManager
        Self.prepareRealmDirectoryIfNeeded(for: configuration, fileManager: fileManager)
        repairInvalidProgressIfNeeded()
    }

    private static func prepareRealmDirectoryIfNeeded(
        for configuration: Realm.Configuration,
        fileManager: FileManager
    ) {
        guard let realmFileURL = configuration.fileURL else { return }
        let directoryURL = realmFileURL.deletingLastPathComponent()
        do {
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                print("✅ Prepared Realm directory: \(directoryURL.path)")
            }
        } catch {
            print("❌ Failed to create Realm directory: \(error)")
        }
    }
    
    var realmConfiguration: Realm.Configuration { configuration }
    
    func saveOrUpdateStatus(quizId: String, status: QuestionStatus) {
        persistStatus(quizId: quizId, chapterId: nil, status: status, updatedAt: Date())
    }
    
    func saveOrUpdateStatus(quizId: String, chapterId: Int, status: QuestionStatus, updatedAt: Date = Date()) {
        persistStatus(quizId: quizId, chapterId: chapterId, status: status, updatedAt: updatedAt)
    }
    
    func saveOrUpdate(progress: QuestionProgress) {
        persistStatus(
            quizId: progress.quizId,
            chapterId: progress.chapterId,
            status: progress.status,
            updatedAt: progress.updatedAt,
            selectedChoiceIndex: progress.selectedAnswerIndex,
            correctChoiceIndex: progress.correctAnswerIndex,
            questionText: progress.questionText,
            choiceTexts: progress.choiceTexts,
            unitId: progress.unitId,
            chapterIdentifier: progress.chapterIdentifier
        )
    }

    func saveOrUpdateAnswerSnapshot(
        quizId: String,
        chapterId: Int,
        unitId: String,
        chapterIdentifier: String,
        status: QuestionStatus,
        selectedChoiceIndex: Int?,
        correctChoiceIndex: Int?,
        questionText: String?,
        choiceTexts: [String],
        updatedAt: Date = Date()
    ) {
        persistStatus(
            quizId: quizId,
            chapterId: chapterId,
            status: status,
            updatedAt: updatedAt,
            selectedChoiceIndex: selectedChoiceIndex,
            correctChoiceIndex: correctChoiceIndex,
            questionText: questionText,
            choiceTexts: choiceTexts,
            unitId: unitId,
            chapterIdentifier: chapterIdentifier
        )
    }
    
    func updateAnswerStatusImmediately(
        quizId: String,
        chapterId: Int,
        status: QuestionStatus,
        selectedChoiceIndex: Int? = nil,
        correctChoiceIndex: Int? = nil,
        questionText: String? = nil,
        choiceTexts: [String]? = nil,
        unitId: String? = nil,
        chapterIdentifier: String? = nil,
        updatedAt: Date = Date()
    ) {
        do {
            let realm = try realm()
            try realm.write {
                let object = realm.create(
                    QuestionProgressObject.self,
                    value: [
                        "quizId": quizId,
                        "chapterId": chapterId,
                        "statusRaw": status.rawValue,
                        "updatedAt": updatedAt
                    ],
                    update: .modified
                )
                object.selectedChoiceIndex = selectedChoiceIndex
                object.correctChoiceIndex = correctChoiceIndex
                if let questionText {
                    object.questionText = questionText
                }
                if let choiceTexts {
                    object.choiceTexts.removeAll()
                    object.choiceTexts.append(objectsIn: choiceTexts)
                }
                if let unitId {
                    object.unitIdentifier = unitId
                }
                if let chapterIdentifier {
                    object.chapterIdentifier = chapterIdentifier
                }
            }
        } catch {
            print("❌ Realm immediate update failed: \(error)")
            return
        }

        NotificationCenter.default.post(
            name: .answerHistoryDidChange,
            object: nil,
            userInfo: ["chapterId": chapterId]
        )
    }
    
    func loadStatuses(chapterId: Int) -> [String: QuestionStatus] {
        do {
            let realm = try realm()
            let objects = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d", chapterId)
            return Dictionary(uniqueKeysWithValues: objects.map { ($0.quizId, $0.status) })
        } catch {
            print("❌ Realm load failed: \(error)")
            return [:]
        }
    }
    func questionProgresses(chapterId: Int) -> [QuestionProgress] {
        do {
            let realm = try realm()
            let progresses = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d", chapterId)
                .map(QuestionProgress.init(object:))
            return Array(progresses)
        } catch {
            print("❌ Realm load failed: \(error)")
            return []
        }
    }
    
    func fetchAnswerHistory(limit: Int? = nil) -> [QuestionProgress] {
        do {
            let realm = try realm()
            let results = realm.objects(QuestionProgressObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: false)
            if let limit {
                return Array(results.prefix(limit).map(QuestionProgress.init(object:)))
            } else {
                return Array(results.map(QuestionProgress.init(object:)))
            }
        } catch {
            print("❌ Realm load failed: \(error)")
            return []
        }
    }

    func observeAnswerHistory(
        limit: Int? = nil,
        onUpdate: @escaping ([QuestionProgress]) -> Void
    ) -> NotificationToken? {
        do {
            let realm = try realm()
            let results = realm.objects(QuestionProgressObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: false)

            let token = results.observe { changes in
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let mapped: [QuestionProgress]
                    if let limit {
                        mapped = Array(collection.prefix(limit).map(QuestionProgress.init(object:)))
                    } else {
                        mapped = Array(collection.map(QuestionProgress.init(object:)))
                    }
                    DispatchQueue.main.async {
                        onUpdate(mapped)
                    }
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }

            return token
        } catch {
            print("❌ Realm observe failed: \(error)")
            return nil
        }
    }
    
    func totalCorrectAnswerCount() -> Int {
        count(for: .correct)
    }
    
    func totalIncorrectAnswerCount() -> Int {
        count(for: .incorrect)
    }
    
    func countCorrectAnswers(for chapterId: Int) -> Int {
        count(for: .correct, chapterId: chapterId)
    }
    
    func currentCorrectStreakCount() -> Int {
        do {
            let realm = try realm()
            let results = realm.objects(QuestionProgressObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: false)
            return Self.currentStreak(from: results)
        } catch {
            print("❌ Realm streak calculation failed: \(error)")
            return 0
        }
    }
    
    func countCorrectAnswers(unitId: String, chapterIdentifier: String) -> Int {
        count(for: .correct, unitId: unitId, chapterIdentifier: chapterIdentifier)
    }
    
    func countIncorrectAnswers(for chapterId: Int) -> Int {
        count(for: .incorrect, chapterId: chapterId)
    }
    
    func totalAnsweredCount() -> Int {
        countAnswered()
    }
    
    func answeredCount(for chapterId: Int) -> Int {
        countAnswered(chapterId: chapterId)
    }
    
    func answeredCount(unitId: String, chapterIdentifier: String) -> Int {
        countAnswered(unitId: unitId, chapterIdentifier: chapterIdentifier)
    }
    
    private func persistStatus(
        quizId: String,
        chapterId: Int?,
        status: QuestionStatus,
        updatedAt: Date,
        selectedChoiceIndex: Int? = nil,
        correctChoiceIndex: Int? = nil,
        questionText: String? = nil,
        choiceTexts: [String]? = nil,
        unitId: String? = nil,
        chapterIdentifier: String? = nil
    ) {
        var notifiedChapterId: Int?
        do {
            let realm = try realm()
            let resolvedChapterId = chapterId ?? IdentifierGenerator.chapterNumericId(fromQuizIdentifier: quizId)
            try realm.write {
                let object: QuestionProgressObject
                if let existing = realm.object(ofType: QuestionProgressObject.self, forPrimaryKey: quizId) {
                    object = existing
                } else {
                    let newObject = QuestionProgressObject()
                    newObject.quizId = quizId
                    object = newObject
                }
                
                if let resolvedChapterId {
                    object.chapterId = resolvedChapterId
                }
                object.status = status
                object.updatedAt = updatedAt
                object.selectedChoiceIndex = selectedChoiceIndex
                object.correctChoiceIndex = correctChoiceIndex

                if let questionText {
                    object.questionText = questionText
                }

                if let choiceTexts {
                    object.choiceTexts.removeAll()
                    object.choiceTexts.append(objectsIn: choiceTexts)
                }

                if let unitId {
                    object.unitIdentifier = unitId
                }

                if let chapterIdentifier {
                    object.chapterIdentifier = chapterIdentifier
                }

                realm.add(object, update: .modified)
                notifiedChapterId = object.chapterId
            }
        } catch {
            print("❌ Realm save failed: \(error)")
            return
        }
        
        if let notifiedChapterId {
            NotificationCenter.default.post(
                name: .answerHistoryDidChange,
                object: nil,
                userInfo: ["chapterId": notifiedChapterId]
            )
        }
    }
    
    private func count(
        for status: QuestionStatus,
        chapterId: Int? = nil,
        unitId: String? = nil,
        chapterIdentifier: String? = nil
    ) -> Int {
        do {
            let realm = try realm()
            var results = realm.objects(QuestionProgressObject.self)
            if let chapterId {
                results = results.filter("chapterId == %d", chapterId)
            }
            if let unitId {
                results = results.filter("unitIdentifier == %@", unitId)
            }
            if let chapterIdentifier {
                results = results.filter("chapterIdentifier == %@", chapterIdentifier)
            }
            return results
                .filter("statusRaw == %@", status.rawValue)
                .count
        } catch {
            print("❌ Realm count failed: \(error)")
            return 0
        }
    }
    
    private func countAnswered(
        chapterId: Int? = nil,
        unitId: String? = nil,
        chapterIdentifier: String? = nil
    ) -> Int {
        do {
            let realm = try realm()
            var results = realm.objects(QuestionProgressObject.self)
            if let chapterId {
                results = results.filter("chapterId == %d", chapterId)
            }
            if let unitId {
                results = results.filter("unitIdentifier == %@", unitId)
            }
            if let chapterIdentifier {
                results = results.filter("chapterIdentifier == %@", chapterIdentifier)
            }
            return results
                .filter("statusRaw != %@", QuestionStatus.unanswered.rawValue)
                .count
        } catch {
            print("❌ Realm count failed: \(error)")
            return 0
        }
    }
    
    private static func currentStreak<S: Sequence>(from sequence: S) -> Int where S.Element == QuestionProgressObject {
        var streak = 0
        for object in sequence {
            switch object.status {
            case .correct:
                streak += 1
            case .incorrect, .unanswered:
                return streak
            }
        }
        return streak
    }
    
    private func realm() throws -> Realm {
        try realmManager.realm(configuration: configuration)
    }
    private func repairInvalidProgressIfNeeded() {
        do {
            let realm = try realm()
            let invalidObjects = realm.objects(QuestionProgressObject.self)
                .filter("unitIdentifier == %@ OR chapterId < %d", "units", 1000)

            guard !invalidObjects.isEmpty else { return }

            let lookup = QuizQuestionCatalog.buildLookup()
            guard !lookup.isEmpty else { return }

            try realm.write {
                for object in invalidObjects {
                    guard let key = QuestionLookupKey(question: object.questionText, choices: Array(object.choiceTexts)) else {
                        continue
                    }
                    guard let entry = lookup[key] else {
                        continue
                    }
                    applyRepairEntry(entry, to: object, in: realm)
                }
            }
        } catch {
            print("❌ Realm repair failed: \(error)")
        }
    }

    private func applyRepairEntry(
        _ entry: QuizQuestionCatalog.Entry,
        to object: QuestionProgressObject,
        in realm: Realm
    ) {
        let newQuizId = "\(entry.unitId)-\(entry.chapterIdentifier)#\(entry.questionIndex)"
        let newChapterId = IdentifierGenerator.chapterNumericId(unitId: entry.unitId, chapterId: entry.chapterIdentifier)

        if let existing = realm.object(ofType: QuestionProgressObject.self, forPrimaryKey: newQuizId), existing !== object {
            merge(object, into: existing, chapterId: newChapterId, unitId: entry.unitId, chapterIdentifier: entry.chapterIdentifier)
            realm.delete(object)
        } else {
            object.quizId = newQuizId
            object.chapterId = newChapterId
            object.unitIdentifier = entry.unitId
            object.chapterIdentifier = entry.chapterIdentifier
        }
    }

    private func merge(
        _ source: QuestionProgressObject,
        into target: QuestionProgressObject,
        chapterId: Int,
        unitId: String,
        chapterIdentifier: String
    ) {
        if source.updatedAt > target.updatedAt {
            target.statusRaw = source.statusRaw
            target.updatedAt = source.updatedAt
            target.selectedChoiceIndex = source.selectedChoiceIndex
            target.correctChoiceIndex = source.correctChoiceIndex
            target.questionText = source.questionText
            target.choiceTexts.removeAll()
            target.choiceTexts.append(objectsIn: Array(source.choiceTexts))
        }
        target.chapterId = chapterId
        target.unitIdentifier = unitId
        target.chapterIdentifier = chapterIdentifier
    }
    func deleteProgress(
        for chapters: Set<ProgressChapterIdentifier>,
        statuses: Set<QuestionStatus>
    ) throws {
        let realm = try realm()
        var objects = realm.objects(QuestionProgressObject.self)

        if !chapters.isEmpty {
            let predicates = chapters.map {
                NSPredicate(
                    format: "unitIdentifier == %@ AND chapterIdentifier == %@",
                    $0.unitId,
                    $0.chapterId
                )
            }
            let compound = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
            objects = objects.filter(compound)
        }

        if !statuses.isEmpty && statuses.count < QuestionStatus.allCases.count {
            let rawValues = statuses.map { $0.rawValue }
            objects = objects.filter("statusRaw IN %@", rawValues)
        }
        guard !objects.isEmpty else { return }
        try realm.write {
            realm.delete(objects)
        }
    }
    func deleteAllProgress() throws {
        try deleteProgress(for: [], statuses: [])
    }

    func deleteAllBookmarks() throws {
        let realm = try realm()
        let bookmarks = realm.objects(BookmarkObject.self)
        guard !bookmarks.isEmpty else { return }
        try realm.write {
            realm.delete(bookmarks)
        }
    }
    func deleteAllData() throws {
        let realm = try realm()
        try realm.write {
            realm.deleteAll()
        }
    }
    
    func observeCorrectCount(for chapterId: Int, onUpdate: @escaping (Int) -> Void) -> NotificationToken? {
        do {
            let realm = try realm()
            let results = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d", chapterId)
            
            let token = results.observe { changes in
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let count = collection.filter("statusRaw == %@", QuestionStatus.correct.rawValue).count
                    DispatchQueue.main.async {
                        onUpdate(count)
                    }
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }
            
            return token
        } catch {
            print("❌ Realm observe failed: \(error)")
            return nil
        }
    }
    func observeChapterProgress(
        for chapterId: Int,
        onUpdate: @escaping ([QuestionProgress]) -> Void
    ) -> NotificationToken? {
        do {
            let realm = try realm()
            let results = realm.objects(QuestionProgressObject.self)
                .filter("chapterId == %d", chapterId)
            
            let token = results.observe { changes in
                switch changes {
                case .initial(let collection), .update(let collection, _, _, _):
                    let progresses = Array(collection.map(QuestionProgress.init(object:)))
                    DispatchQueue.main.async {
                        onUpdate(progresses)
                    }
                case .error(let error):
                    print("❌ Realm observe failed: \(error)")
                }
            }
            
            return token
        } catch {
            print("❌ Realm observe failed: \(error)")
            return nil
        }
    }
}

extension Notification.Name {
    static let answerHistoryDidChange = Notification.Name("answerHistoryDidChange")
}
