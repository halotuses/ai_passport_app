// Models/Quiz.swift
import Foundation

struct Quiz: Codable, Identifiable, Hashable {
    // 画面用の一時ID（サーバJSONには id が無い）
    var id = UUID()

    /// 章ファイル内での並び順を特定するための識別子
    let orderRef: String?
    let question: String
    let choices: [String]
    let answerIndex: Int
    let explanation: String?

    init(
        id: UUID = UUID(),
        orderRef: String? = nil,
        question: String,
        choices: [String],
        answerIndex: Int,
        explanation: String?
    ) {
        self.id = id
        self.orderRef = orderRef
        self.question = question
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
    }
    
    // ← JSONに存在するキーだけを列挙（id を入れないことがポイント）
    enum CodingKeys: String, CodingKey {
        case orderRef
        case question
        case choices
        case answerIndex
        case explanation
    }
}
