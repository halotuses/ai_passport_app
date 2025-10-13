// ViewModels/ChapterListViewModel.swift
import Foundation

class ChapterListViewModel: ObservableObject {

    @Published var chapters: [ChapterMetadata] = []
    @Published var quizCounts: [String: Int] = [:]
    @Published var correctCounts: [String: Int] = [:]

    private let repository = AnswerHistoryRepository()

    func fetchChapters(from filePath: String) {
        let fullURL = Constants.url(filePath)
        NetworkManager.fetchChapterList(from: fullURL) { [weak self] result in
            self?.chapters = result?.chapters ?? []
            self?.calculateQuizCounts()
            self?.calculateCorrectCounts()
        }
    }

    private func calculateQuizCounts() {
        for chapter in chapters {
            let quizURL = Constants.url(chapter.file)
            NetworkManager.fetchQuizList(from: quizURL) { [weak self] quizList in
                DispatchQueue.main.async {
                    self?.quizCounts[chapter.id] = quizList?.questions.count ?? 0
                }
            }
        }
    }

    private func calculateCorrectCounts() {
        DispatchQueue.main.async {
            for chapter in self.chapters {
                let chapterIdInt = Int(chapter.id) ?? 0
                self.correctCounts[chapter.id] = self.repository.countCorrectAnswers(for: chapterIdInt)
            }
        }
    }
}
