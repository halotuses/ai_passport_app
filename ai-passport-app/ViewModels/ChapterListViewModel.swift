// ViewModels/ChapterListViewModel.swift
import Foundation
import RealmSwift

class ChapterListViewModel: ObservableObject {
    
    @Published var chapters: [ChapterMetadata] = []
    @Published var progressViewModels: [ChapterProgressViewModel] = []
    
    private let repository: RealmAnswerHistoryRepository
    
    private var currentUnitId: String = ""
    private var progressLookup: [String: ChapterProgressViewModel] = [:]
    
    init(repository: RealmAnswerHistoryRepository = RealmAnswerHistoryRepository()) {
        self.repository = repository
    }
    
    
    func fetchChapters(forUnitId unitId: String, filePath: String) {
        if unitId.hasPrefix("unit") {
            currentUnitId = unitId
        } else {
            currentUnitId = extractUnitIdentifier(from: filePath)
        }
        chapters = []
        progressViewModels.removeAll()
        progressLookup.removeAll()
        
        let fullURL = Constants.url(filePath)
        NetworkManager.fetchChapterList(from: fullURL) { [weak self] result in
            guard let self else { return }
            let fetchedChapters = result?.chapters ?? []
            // Task を使って MainActor 上で UI 状態と子 ViewModel を更新
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.chapters = fetchedChapters
                self.buildProgressViewModels()
                self.calculateQuizCounts()
            }
        }
    }
    
    private func calculateQuizCounts() {
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
    
    @MainActor
    private func buildProgressViewModels() {
        // MainActor 上で ChapterProgressViewModel を生成して UI バインディングの整合性を保つ
        let models = chapters.map { chapter in
            ChapterProgressViewModel(unitId: currentUnitId, chapter: chapter, repository: repository)
        }
        progressViewModels = models
        progressLookup = Dictionary(uniqueKeysWithValues: models.map { ($0.id, $0) })
    }
    
    private func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        if let unitComponent = components.first(where: { $0.hasPrefix("unit") }) {
            return String(unitComponent)
        }
        return ""
    }
}
