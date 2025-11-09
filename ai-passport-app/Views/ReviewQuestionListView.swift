import SwiftUI

struct ReviewQuestionListView: View {
    let unit: ReviewUnitListViewModel.ReviewUnit
    let chapter: ReviewUnitListViewModel.ReviewChapter
    let headerTitle: String
    let onSelect: (ReviewUnitSelection) -> Void
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
                            let selection = ReviewUnitSelection(
                                unitId: unit.unitId,
                                unit: unit.unit,
                                chapter: chapter.chapter,
                                initialQuestionIndex: question.questionIndex,
                                questions: chapter.questions
                            )
                            onSelect(selection)
                        } label: {
                            questionRow(question)
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
        .onAppear(perform: configureHeader)
    }
}

private extension ReviewQuestionListView {
    func configureHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "\(headerTitle)（\(unit.unit.title)・\(chapter.chapter.title)）"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundColor(.themeTextSecondary)
            Text("復習できる問題が見つかりませんでした。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    func questionRow(_ question: ReviewUnitListViewModel.ReviewChapter.ReviewQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Text("第\(question.questionIndex + 1)問")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
                statusBadge(for: question.progress.status)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
            }

            Text(question.progress.questionText ?? "問題文を表示できませんでした。")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .multilineTextAlignment(.leading)

            if question.progress.status.isAnswered,
               let selected = question.progress.selectedChoiceText {
                Text("前回の回答: \(selected)")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
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
                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 8)
    }

    func statusBadge(for status: QuestionStatus) -> some View {
        let descriptor = statusDescriptor(for: status)
        return Text(descriptor.title)
            .font(.caption.weight(.semibold))
            .foregroundColor(descriptor.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(descriptor.tint.opacity(0.15), in: Capsule())
    }

    func statusDescriptor(for status: QuestionStatus) -> (title: String, tint: Color) {
        switch status {
        case .correct:
            return ("正解", .themeCorrect)
        case .incorrect:
            return ("不正解", .themeIncorrect)
        case .unanswered:
            return ("未解答", .themeTextSecondary)
        }
    }
}
