import Foundation

struct ReviewUnitSelection: Sendable {
    let unitId: String
    let unit: QuizMetadata
    let chapter: ChapterMetadata
    let initialQuestionIndex: Int
    let questions: [ReviewUnitListViewModel.ReviewChapter.ReviewQuestion]
}
