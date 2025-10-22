// ViewModels/ChapterListViewModel.swift
import Foundation
import RealmSwift

class ChapterListViewModel: ObservableObject {
    
    @Published var chapters: [ChapterMetadata] = []
    @Published var quizCounts: [String: Int] = [:]
    @Published var correctCounts: [String: Int] = [:]
    
    private let repository: RealmAnswerHistoryRepository
    
    private var currentUnitId: String = ""
    private var progressTokens: [String: NotificationToken] = [:]
    
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
        invalidateProgressTokens()
        
        
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
        invalidateProgressTokens()
        var updatedCounts: [String: Int] = [:]

        for chapter in chapters {
            let chapterKey = chapter.id
            let identifier = IdentifierGenerator.chapterNumericId(unitId: currentUnitId, chapterId: chapter.id)
            let initialCount = repository.countCorrectAnswers(for: identifier)
            updatedCounts[chapterKey] = initialCount

            if let token = repository.observeCorrectCount(for: identifier, onUpdate: { [weak self] correctCount in
                guard let self else { return }
                self.correctCounts[chapterKey] = correctCount
            }) {
                progressTokens[chapterKey] = token
            }
        }
        
        correctCounts = updatedCounts
    }
    
    
    
    private func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        if let unitComponent = components.first(where: { $0.hasPrefix("unit") }) {
            return String(unitComponent)
        }
        return ""
    }
    
    deinit {
        invalidateProgressTokens()
    }

    private func invalidateProgressTokens() {
        progressTokens.values.forEach { $0.invalidate() }
        progressTokens.removeAll()
    }
}
