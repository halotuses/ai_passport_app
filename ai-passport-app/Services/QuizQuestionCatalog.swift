import Foundation

struct QuizQuestionCatalog {
    struct Entry {
        let unitId: String
        let chapterIdentifier: String
        let questionIndex: Int
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()

    static func buildLookup(bundle: Bundle = .main) -> [QuestionLookupKey: Entry] {
        guard let metadataData = data(forResourcePath: "quizzes/metadata/quizzes_metadata.json", bundle: bundle),
              let metadata = try? decoder.decode(QuizMetadataMap.self, from: metadataData) else {
            return [:]
        }

        var results: [QuestionLookupKey: Entry] = [:]

        for (unitId, unit) in metadata {
            guard let chapterListData = data(forResourcePath: unit.file, bundle: bundle),
                  let chapterList = try? decoder.decode(ChapterList.self, from: chapterListData) else {
                continue
            }

            for chapter in chapterList.chapters {
                guard let quizData = data(forResourcePath: chapter.file, bundle: bundle),
                      let quizList = try? decoder.decode(QuizList.self, from: quizData) else {
                    continue
                }

                for (index, quiz) in quizList.questions.enumerated() {
                    guard let key = QuestionLookupKey(question: quiz.question, choices: quiz.choices) else { continue }
                    results[key] = Entry(unitId: unitId, chapterIdentifier: chapter.id, questionIndex: index)
                }
            }
        }

        return results
    }

    private static func data(forResourcePath path: String, bundle: Bundle) -> Data? {
        let cleanedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let components = cleanedPath.split(separator: "/")
        guard let fileComponent = components.last else { return nil }
        let directoryComponents = components.dropLast()

        let fileParts = fileComponent.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard fileParts.count == 2 else { return nil }

        let resourceName = String(fileParts[0])
        let fileExtension = String(fileParts[1])
        let subdirectory = directoryComponents.joined(separator: "/")

        let candidateBundles: [Bundle]
        if bundle === Bundle.main {
            candidateBundles = [bundle, Bundle(for: BundleToken.self)]
        } else {
            candidateBundles = [bundle]
        }

        for candidate in candidateBundles {
            if let url = candidate.url(forResource: resourceName, withExtension: fileExtension, subdirectory: subdirectory) {
                if let data = try? Data(contentsOf: url) {
                    return data
                }
            }
        }

        return nil
    }
}

private final class BundleToken {}

struct QuestionLookupKey: Hashable {
    let question: String
    let choices: [String]

    init?(question: String?, choices: [String]) {
        guard let question, !question.isEmpty else { return nil }
        self.question = question
        self.choices = choices
    }

    init?(question: String, choices: [String]) {
        guard !question.isEmpty else { return nil }
        self.question = question
        self.choices = choices
    }
}
