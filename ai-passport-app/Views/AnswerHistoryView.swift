import SwiftUI

@MainActor
struct AnswerHistoryView: View {
    @StateObject private var viewModel: AnswerHistoryViewModel

    init(viewModel: AnswerHistoryViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AnswerHistoryViewModel())
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.histories.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .navigationTitle("回答履歴")
        .background(Color.themeBase.ignoresSafeArea())
        .onAppear {
            viewModel.refresh()
        }
    }

    private var historyList: some View {
        List {
            ForEach(viewModel.histories) { history in
                AnswerHistoryRow(history: history)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await MainActor.run {
                viewModel.refresh()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundColor(.themeTextSecondary)
            Text("まだ回答履歴がありません")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            Text("クイズに挑戦すると、ここに回答内容が表示されます。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AnswerHistoryRow: View {
    let history: QuestionProgress

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            questionSection
            answerSection
        }
        .padding(.vertical, 8)
    }

    private var header: some View {
        HStack {
            Text(history.displayLocation)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
            Spacer()
            Text(Self.dateFormatter.string(from: history.updatedAt))
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(history.questionText ?? "問題ID: \(history.quizId)")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .multilineTextAlignment(.leading)
            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(history.status.displayLabel)
            .font(.caption.weight(.semibold))
            .foregroundColor(history.status.foregroundColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(history.status.backgroundColor)
            .clipShape(Capsule())
    }

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let selectedText = history.selectedChoiceText {
                LabeledContent("あなたの回答", value: selectedText)
                    .foregroundColor(history.isCorrect ? .themeCorrect : .themeIncorrect)
            } else {
                Text("未回答")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }

            if let correctText = history.correctChoiceText, !history.isCorrect {
                LabeledContent("正しい答え", value: correctText)
                    .foregroundColor(.themeCorrect)
            }
        }
        .font(.subheadline)
    }
}

private extension QuestionStatus {
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
