// Models/Quiz.swift
import Foundation

struct Quiz: Codable, Identifiable, Hashable {
    // 画面用の一時ID（サーバJSONには id が無い）
    var id = UUID()

    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?

    // ← JSONに存在するキーだけを列挙（id を入れないことがポイント）
    enum CodingKeys: String, CodingKey {
        case question
        case choices
        case answerIndex
        case explanation
    }
}
