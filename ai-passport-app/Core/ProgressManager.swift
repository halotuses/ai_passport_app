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
        NotificationCenter.default.post(name: .bookmarkDidChange, object: quizId)
    }

    func isBookmarked(_ quizId: String) -> Bool {
        repository.isBookmarked(quizId: quizId)
    }

    func setBookmark(quizId: String, questionText: String, isBookmarked: Bool) {
        let userId: String
        if let stored = UserDefaults.standard.string(forKey: QuizViewModel.bookmarkUserIdKey) {
            userId = stored
        } else {
            let created = UUID().uuidString
            UserDefaults.standard.set(created, forKey: QuizViewModel.bookmarkUserIdKey)
            userId = created
        }
        repository.setBookmark(
            quizId: quizId,
            userId: userId,
            questionText: questionText,
            isBookmarked: isBookmarked
        )
        NotificationCenter.default.post(name: .bookmarkDidChange, object: quizId)
    }
    
}

extension Notification.Name {
    static let bookmarkDidChange = Notification.Name("bookmarkDidChange")
}
