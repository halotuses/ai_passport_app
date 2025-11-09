import Foundation
import SwiftUI

enum ReviewCategory: CaseIterable, Hashable, Sendable {
    case bookmark
    case correct
    case incorrect

    var title: String {
        switch self {
        case .bookmark:
            return "ブックマークした問題"
        case .correct:
            return "正解した問題"
        case .incorrect:
            return "不正解だった問題"
        }
    }

    var description: String {
        switch self {
        case .bookmark:
            return "後で見返したい問題をまとめています。"
        case .correct:
            return "正解できた問題も定期的に復習して定着させましょう。"
        case .incorrect:
            return "苦手な問題を重点的に振り返りましょう。"
        }
    }

    var iconName: String {
        switch self {
        case .bookmark:
            return "bookmark.fill"
        case .correct:
            return "checkmark.circle.fill"
        case .incorrect:
            return "xmark.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .bookmark:
            return .themeAccent
        case .correct:
            return .themeCorrect
        case .incorrect:
            return .themeIncorrect
        }
    }

    var emptyMessage: String {
        switch self {
        case .bookmark:
            return "ブックマークした問題はまだありません。"
        case .correct:
            return "まだ正解した問題はありません。"
        case .incorrect:
            return "不正解の問題はありません。"
        }
    }

    var unitSelectionHeader: String {
        switch self {
        case .bookmark:
            return "ブックマークした問題"
        case .correct:
            return "正解した問題"
        case .incorrect:
            return "不正解だった問題"
        }
    }

    var playHeaderPrefix: String {
        switch self {
        case .bookmark:
            return "ブックマーク復習"
        case .correct:
            return "正解復習"
        case .incorrect:
            return "不正解復習"
        }
    }
}
