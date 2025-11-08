import Foundation

@MainActor
final class CorrectAnswerChapterViewModel: ObservableObject {
    struct ChapterItem: Identifiable {
        let id: String
        let chapter: ChapterMetadata
        let entry: CorrectAnswerView.ChapterEntry?
        let progressViewModel: ChapterProgressViewModel

        var correctCount: Int { entry?.correctCount ?? 0 }
    }

    @Published private(set) var chapterItems: [ChapterItem] = []

    private let unit: CorrectAnswerView.UnitEntry
    private let repository: RealmAnswerHistoryRepository
    private var progressLookup: [String: ChapterProgressViewModel] = [:]

    init(
        unit: CorrectAnswerView.UnitEntry,
        repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()
    ) {
        self.unit = unit
        self.repository = repository
        load()
    }

    private func load() {
        let chapterListURL = Constants.url(unit.unit.file)
         NetworkManager.fetchChapterList(from: chapterListURL) { [weak self] chapterList in
             guard let self else { return }
             let fetchedChapters = chapterList?.chapters ?? []

             Task { @MainActor [weak self] in
                 guard let self else { return }
                 if fetchedChapters.isEmpty {
                     let fallbackChapters = unit.chapters.map(\.chapter)
                     buildChapterItems(from: fallbackChapters)
                     fetchQuizCounts(for: fallbackChapters)
                 } else {
                     buildChapterItems(from: fetchedChapters)
                     fetchQuizCounts(for: fetchedChapters)
                 }
             }
         }
     }

     @MainActor
     private func buildChapterItems(from chapters: [ChapterMetadata]) {
         let entriesMap = Dictionary(uniqueKeysWithValues: unit.chapters.map { ($0.id, $0) })
         progressLookup.removeAll()

         let items: [ChapterItem] = chapters.map { chapter in
             let progressViewModel = ChapterProgressViewModel(
                 unitId: unit.unitId,
                 chapter: chapter,
                 repository: repository
             )
             progressLookup[chapter.id] = progressViewModel
             return ChapterItem(
                 id: chapter.id,
                 chapter: chapter,
                 entry: entriesMap[chapter.id],
                 progressViewModel: progressViewModel
             )
         }

         chapterItems = items
     }

     private func fetchQuizCounts(for chapters: [ChapterMetadata]) {
         for chapter in chapters {
             let quizPath = normalizedQuizPath(from: chapter.file)
             let quizURL = Constants.url(quizPath)
             NetworkManager.fetchQuizList(from: quizURL) { [weak self] quizList in
                 guard let self else { return }
                 let count = quizList?.questions.count ?? 0
                 DispatchQueue.main.async {
                     self.progressLookup[chapter.id]?.updateTotalQuestions(count)
                 }
             }
         }
     }

     private func normalizedQuizPath(from path: String) -> String {
         var normalizedPath = path
         if normalizedPath.hasPrefix("/") {
             normalizedPath.removeFirst()
         }
         if !normalizedPath.hasPrefix("quizzes/") {
             normalizedPath = "quizzes/" + normalizedPath
        }
         return normalizedPath
    }
}
