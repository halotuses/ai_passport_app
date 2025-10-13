import Foundation

/// モデル: 単元メタ情報
struct QuizMetadata: Decodable, Hashable {
    let version: String
    let file: String
    let title: String
    let subtitle: String
    let total: Int
}

typealias QuizMetadataMap = [String: QuizMetadata]
