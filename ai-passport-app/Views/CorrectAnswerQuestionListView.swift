import SwiftUI

struct CorrectAnswerQuestionListView: View {
    let chapter: CorrectAnswerView.ChapterEntry
    let onSelect: @Sendable (CorrectAnswerView.ChapterEntry.QuestionEntry) -> Void
    let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if chapter.questions.isEmpty {
                    emptyState
                } else {
                    ForEach(chapter.questions) { question in
                        Button {
                            SoundManager.shared.play(.tap)
                            onSelect(question)
                        } label: {
                            questionRow(for: question)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.themeBase
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
        .onAppear { setHeader() }
    }
}

private extension CorrectAnswerQuestionListView {
    func setHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "◀ 正解した問題",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "\(chapter.chapter.title)（正解済み問題）"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundColor(.themeTextSecondary)
            Text("この章で正解した問題はまだありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    func questionRow(for question: CorrectAnswerView.ChapterEntry.QuestionEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("第\(question.questionIndex + 1)問")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
            }

            Text(question.questionText)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .multilineTextAlignment(.leading)

            if let selectedText = question.progress.selectedChoiceText {
                Text("あなたの回答: \(selectedText)")
                    .font(.footnote)
                    .foregroundColor(.themeCorrect)
            }
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
}

#Preview {
    let question = CorrectAnswerView.ChapterEntry.QuestionEntry(
        id: "unit1-ch1#0",
        quizId: "unit1-ch1#0",
        questionIndex: 0,
        progress: QuestionProgress(
            quizId: "unit1-ch1#0",
            chapterId: 1,
            status: .correct,
            unitId: "unit1",
            chapterIdentifier: "chapter1",
            selectedAnswerIndex: 0,
            correctAnswerIndex: 0,
            questionText: "サンプル問題",
            choiceTexts: ["A", "B", "C", "D"]
        )
    )

    CorrectAnswerQuestionListView(
        chapter: CorrectAnswerView.ChapterEntry(
            id: "chapter1",
            chapter: ChapterMetadata(id: "chapter1", title: "サンプル章", file: ""),
            questions: [question]
        ),
        onSelect: { _ in },
        onClose: {}
    )
    .environmentObject(MainViewState())
}
