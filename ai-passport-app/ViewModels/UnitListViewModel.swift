
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
            self.quizCounts = Self.buildQuizCounts(from: result)
            self.isLoading = false
            self.hasLoadedOnce = (result != nil)
        }
    }
    
    func refreshIfNeeded() {
        if !hasLoadedOnce {
            fetchMetadata()
        }
    }
    
    private static func buildQuizCounts(from metadata: QuizMetadataMap?) -> [String: Int] {
        guard let metadata else { return [:] }
        var counts: [String: Int] = [:]
        for (key, value) in metadata {
            counts[key] = value.total
            
        }
        return counts
    }
}
