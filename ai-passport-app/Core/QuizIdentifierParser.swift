import Foundation

enum QuizIdentifierParser {
    struct Components {
        let unitId: String
        let chapterId: String
        let questionIndex: Int?
    }

    static func parse(_ identifier: String) -> Components? {
        let components = identifier.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        guard let unitAndChapterComponent = components.first else { return nil }

        let unitAndChapter = unitAndChapterComponent.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        guard unitAndChapter.count == 2 else { return nil }

        let questionIndex: Int?
        if components.count > 1 {
            questionIndex = Int(components[1])
        } else {
            questionIndex = nil
        }

        return Components(
            unitId: String(unitAndChapter[0]),
            chapterId: String(unitAndChapter[1]),
            questionIndex: questionIndex
        )
    }
}
