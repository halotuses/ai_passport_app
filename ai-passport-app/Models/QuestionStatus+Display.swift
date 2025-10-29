import SwiftUI

extension QuestionStatus {
    var displayLabel: String {
        switch self {
        case .correct:
            return "正解"
        case .incorrect:
            return "不正解"
        case .unanswered:
            return "未回答"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .correct:
            return Color.themeCorrect.opacity(0.15)
        case .incorrect:
            return Color.themeIncorrect.opacity(0.15)
        case .unanswered:
            return Color.themeTextSecondary.opacity(0.1)
        }
    }

    var foregroundColor: Color {
        switch self {
        case .correct:
            return Color.themeCorrect
        case .incorrect:
            return Color.themeIncorrect
        case .unanswered:
            return Color.themeTextSecondary
        }
    }
}
