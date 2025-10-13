import Foundation

struct NetworkManager {

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
            #if DEBUG
            print("❌ URL作成失敗: \(urlString)")
            #endif
            DispatchQueue.main.async { completion(nil) }
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        #if DEBUG
        print("🌏 GET:", url.absoluteString)
        #endif

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                #if DEBUG
                print("❌ 通信エラー:", error.localizedDescription)
                #endif
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let data = data else {
                #if DEBUG
                print("❌ データなし")
                #endif
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let decoder = JSONDecoder()
                // JSONのキーはそのまま（snake→camel の変換はしない）
                let decoded = try decoder.decode(T.self, from: data)
                DispatchQueue.main.async { completion(decoded) }
            } catch {
                #if DEBUG
                print("❌ デコード失敗:", error)
                if let text = String(data: data, encoding: .utf8) {
                    print("📄 受信JSON:\n\(text)")
                } else {
                    print("📄 受信JSON \(data.count) bytes（文字列化不可）")
                }
                #endif
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
}
