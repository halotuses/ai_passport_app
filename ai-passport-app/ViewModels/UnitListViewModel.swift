// ViewModels/UnitListViewModel.swift
import Foundation

/// 単元一覧データ取得用 ViewModel
class UnitListViewModel: ObservableObject {

    @Published var metadata: QuizMetadataMap?
    @Published var quizCounts: [String: Int] = [:]

    func fetchMetadata() {
        NetworkManager.fetchMetadata { [weak self] data in
            self?.metadata = data
            self?.calculateTotalCounts()
        }
    }

    private func calculateTotalCounts() {
        guard let metadata = metadata else { return }
        for (key, unit) in metadata {
            fetchChapterCount(for: key, unit: unit)
        }
    }

    private func fetchChapterCount(for key: String, unit: QuizMetadata) {
        let chapterURL = Constants.url(unit.file)
        NetworkManager.fetchChapterList(from: chapterURL) { chapterList in
            var total = 0
            chapterList?.chapters.forEach { chapter in
                let quizURL = Constants.url(chapter.file)
                NetworkManager.fetchQuizList(from: quizURL) { quizList in
                    total += quizList?.questions.count ?? 0
                    DispatchQueue.main.async {
                        self.quizCounts[key] = total
                    }
                }
            }
        }
    }
}
