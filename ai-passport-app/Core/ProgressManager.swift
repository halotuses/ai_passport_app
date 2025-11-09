import Foundation
import SwiftUI

@MainActor
final class ProgressManager: ObservableObject {
    let repository: RealmAnswerHistoryRepository
    let homeProgressViewModel: HomeProgressViewModel
    let homeViewModel: HomeViewModel
    let chapterListViewModel: ChapterListViewModel
    let quizViewModel: QuizViewModel

    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository

        let homeProgressViewModel = HomeProgressViewModel(repository: repository)
        self.homeProgressViewModel = homeProgressViewModel
        self.homeViewModel = HomeViewModel(progressViewModel: homeProgressViewModel)
        self.chapterListViewModel = ChapterListViewModel(repository: repository)
        self.quizViewModel = QuizViewModel(repository: repository)
    }
    
    func bookmarkedProgresses(for userId: String) -> [QuestionProgress] {
        repository.bookmarkedProgresses(for: userId)
    }

    func removeBookmark(with quizId: String) {
        repository.removeBookmark(with: quizId)
    }
    
}
