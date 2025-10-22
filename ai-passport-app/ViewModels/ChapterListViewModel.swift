// ViewModels/ChapterListViewModel.swift
import Foundation

class ChapterListViewModel: ObservableObject {
    
    @Published var chapters: [ChapterMetadata] = []
    @Published var quizCounts: [String: Int] = [:]
    @Published var correctCounts: [String: Int] = [:]
    
    private let repository: RealmAnswerHistoryRepository
    
    private var currentUnitId: String = ""
    
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
        quizCounts.removeAll()
        correctCounts.removeAll()
        
        
        let fullURL = Constants.url(filePath)
        NetworkManager.fetchChapterList(from: fullURL) { [weak self] result in
            
            guard let self else { return }
            
            let fetchedChapters = result?.chapters ?? []
            DispatchQueue.main.async {
                self.chapters = fetchedChapters
                self.calculateQuizCounts()
                self.calculateCorrectCounts()
            }
            
        }
    }
    
    private func calculateQuizCounts() {
        for chapter in chapters {
            let quizURL = Constants.url(chapter.file)
            NetworkManager.fetchQuizList(from: quizURL) { [weak self] quizList in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard self.chapters.contains(chapter) else { return }
                    self.quizCounts[chapter.id] = quizList?.questions.count ?? 0
                }
            }
        }
    }
    
    private func calculateCorrectCounts() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            var counts: [String: Int] = [:]
            
            for chapter in self.chapters {
                let identifier = IdentifierGenerator.chapterNumericId(unitId: self.currentUnitId, chapterId: chapter.id)
                let correctCount = self.repository.countCorrectAnswers(for: identifier)
                counts[chapter.id] = correctCount
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.correctCounts = counts
            }
        }
    }
    
    
    
    private func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        if let unitComponent = components.first(where: { $0.hasPrefix("unit") }) {
            return String(unitComponent)
        }
        return ""
    }
    
}
