import Foundation

struct ExplanationRoute: Hashable, Identifiable {
    let id = UUID()
    let quiz: Quiz
    let selectedAnswerIndex: Int
}
