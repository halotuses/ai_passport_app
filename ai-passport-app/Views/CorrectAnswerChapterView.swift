import SwiftUI

struct CorrectAnswerChapterView: View {
    let unit: CorrectAnswerView.UnitEntry
    let onClose: () -> Void

    @StateObject private var viewModel: CorrectAnswerChapterViewModel
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    init(
        unit: CorrectAnswerView.UnitEntry,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: CorrectAnswerChapterViewModel(unit: unit))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.chapterItems.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.chapterItems) { chapter in
                        if let entry = chapter.entry, chapter.correctCount > 0 {
                            NavigationLink {
                                CorrectAnswerQuestionListView(
                                    unit: unit,
                                    chapter: entry,
                                    onClose: { setHeader() }
                                )
                            } label: {
                                ChapterCardView(
                                    viewModel: chapter.progressViewModel,
                                    badgeDisplayMode: .ratio,
                                    badgeCorrectCount: chapter.correctCount
                                )
                            }
                            .buttonStyle(.plain)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    SoundManager.shared.play(.tap)
                                }
                            )
                        } else {
                            ChapterCardView(
                                viewModel: chapter.progressViewModel,
                                isDisabled: true,
                                badgeDisplayMode: .ratio,
                                badgeCorrectCount: chapter.correctCount
                            )
                            .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .navigationBarBackButtonHidden(true)
        .onAppear { setHeader() }
    }
}

private extension CorrectAnswerChapterView {
    func setHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "◀ 正解した問題",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "正解復習（\(unit.unit.title)）"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.themeCorrect)
            Text("この単元で正解した章はまだありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    CorrectAnswerChapterView(
        unit: CorrectAnswerView.UnitEntry(
            id: "unit1",
            unitId: "unit1",
            unit: QuizMetadata(version: "1", file: "", title: "サンプル単元", subtitle: "Sample", total: 0),
            chapters: []
        ),
        onClose: {}
    )
    .environmentObject(MainViewState())
}
