
import Foundation

@MainActor
final class UnitListViewModel: ObservableObject {
    
    @Published private(set) var metadata: QuizMetadataMap?
    @Published private(set) var quizCounts: [String: Int] = [:]
    @Published private(set) var isLoading = false
    
    private var hasLoadedOnce = false
    
    func fetchMetadata() {
        guard !isLoading else { return }
        isLoading = true
        
        NetworkManager.fetchMetadata { [weak self] result in
            guard let self else { return }
            self.metadata = result
            self.quizCounts = Self.buildInitialQuizCounts(from: result)
            self.isLoading = false
            self.hasLoadedOnce = (result != nil)
            self.loadQuizCounts(from: result)
        }
    }
    
    func refreshIfNeeded() {
        if !hasLoadedOnce {
            fetchMetadata()
        }
    }
    
    private static func buildQuizCounts(from metadata: QuizMetadataMap?) -> [String: Int] {
        private static func buildInitialQuizCounts(from metadata: QuizMetadataMap?) -> [String: Int] {
        guard let metadata else { return [:] }
        var counts: [String: Int] = [:]
        for (key, value) in metadata {
            counts[key] = value.total
            
        }
        return counts
    }
        private func loadQuizCounts(from metadata: QuizMetadataMap?) {
               guard let metadata else { return }

               let unitGroup = DispatchGroup()
               var counts: [String: Int] = Self.buildInitialQuizCounts(from: metadata)

               for (key, unit) in metadata {
                   unitGroup.enter()
                   let chapterListURL = Constants.url(unit.file)

                   NetworkManager.fetchChapterList(from: chapterListURL) { chapterList in
                       guard let chapters = chapterList?.chapters, !chapters.isEmpty else {
                           unitGroup.leave()
                           return
                       }

                       var total = 0
                       let chapterGroup = DispatchGroup()

                       for chapter in chapters {
                           chapterGroup.enter()
                           let quizURL = Constants.url(chapter.file)

                           NetworkManager.fetchQuizList(from: quizURL) { quizList in
                               total += quizList?.questions.count ?? 0
                               chapterGroup.leave()
                           }
                       }

                       chapterGroup.notify(queue: .main) {
                           counts[key] = total
                           unitGroup.leave()
                       }
                   }
               }

               unitGroup.notify(queue: .main) { [weak self] in
                   self?.quizCounts = counts
               }
           }
}
