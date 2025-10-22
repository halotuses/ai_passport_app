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
            DispatchQueue.main.async {
                self.chapters = fetchedChapters
                self.buildProgressViewModels()
                self.calculateQuizCounts()
            }
            
        }
    }
    
    private func calculateQuizCounts() {
        for chapter in chapters {
            let quizURL = Constants.url(chapter.file)
            NetworkManager.fetchQuizList(from: quizURL) { [weak self] quizList in
                guard let self else { return }
                let count = quizList?.questions.count ?? 0
                DispatchQueue.main.async {
                    self.progressLookup[chapter.id]?.updateTotalQuestions(count)
                }
            }
        }
    }
    
    private func buildProgressViewModels() {
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
