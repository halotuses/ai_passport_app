import SwiftUI

@MainActor
struct AnswerHistoryView: View {
    @StateObject private var viewModel: AnswerHistoryViewModel
    @EnvironmentObject private var mainViewState: MainViewState

    init(viewModel: AnswerHistoryViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AnswerHistoryViewModel())
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Color.themeBase
                    .ignoresSafeArea()
            )
            .onAppear {
                mainViewState.setHeader(title: "回答履歴", backButton: .toHome)
                viewModel.refresh()
            }
            .navigationBarBackButtonHidden(true)
    }
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("読み込み中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.histories.isEmpty {
            emptyState
        } else {
            historyList
        }
    }

    
    private var historyList: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.histories) { history in
                    AnswerHistoryRow(history: history)
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
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
        .padding(24)
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
        VStack(alignment: .leading, spacing: 16) {
            header
            questionSection
            answerSection
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.themeSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 8)
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
