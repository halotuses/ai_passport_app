import Foundation

@MainActor
final class CorrectAnswerChapterViewModel: ObservableObject {
    struct CorrectChapter: Identifiable {
        let id: String
        let entry: CorrectAnswerView.ChapterEntry

        var title: String { entry.chapter.title }
        var correctCount: Int { entry.correctCount }
        var questions: [CorrectAnswerView.ChapterEntry.QuestionEntry] { entry.questions }
    }

    @Published private(set) var correctChapters: [CorrectChapter] = []

    private let unit: CorrectAnswerView.UnitEntry

    init(unit: CorrectAnswerView.UnitEntry) {
        self.unit = unit
        load()
    }

    private func load() {
        correctChapters = unit.chapters.map { chapter in
            CorrectChapter(id: chapter.id, entry: chapter)
        }
    }
}
