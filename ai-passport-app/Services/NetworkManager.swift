import Foundation

struct NetworkManager {
    //test
    
    static func fetchMetadata(completion: @escaping (QuizMetadataMap?) -> Void) {
        let path = "quizzes/metadata/quizzes_metadata.json?nocache=\(UUID().uuidString)"
        let urlStr = Constants.url(path)
        fetch(urlString: urlStr, type: QuizMetadataMap.self, completion: completion)
    }
    
    static func fetchChapterList(from urlString: String, completion: @escaping (ChapterList?) -> Void) {
        fetch(urlString: urlString, type: ChapterList.self, completion: completion)
    }
    
    static func fetchQuizList(from urlString: String, completion: @escaping (QuizList?) -> Void) {
        fetch(urlString: urlString, type: QuizList.self, completion: completion)
    }
    
    // MARK: - Private
    
    private static func fetch<T: Decodable>(
        urlString: String,
        type: T.Type,
        completion: @escaping (T?) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // JSONのキーはそのまま（snake→camel の変換はしない）
                let decoded = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async { completion(decoded) }
            } catch {
                
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
}
