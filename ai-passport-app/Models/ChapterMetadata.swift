import Foundation

struct ChapterMetadata: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let file: String
}
