import SwiftUI

struct IncorrectAnswerChapterView: View {
    let unit: IncorrectAnswerView.UnitEntry
    let onClose: () -> Void

    @StateObject private var viewModel: IncorrectAnswerChapterViewModel
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    init(
        unit: IncorrectAnswerView.UnitEntry,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.onClose = onClose
        _viewModel = StateObject(wrappedValue: IncorrectAnswerChapterViewModel(unit: unit))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.chapterItems.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.chapterItems) { chapter in
                        if let entry = chapter.entry, chapter.incorrectCount > 0 {
                            NavigationLink {
                                IncorrectAnswerQuestionListView(
                                    unit: unit,
                                    chapter: entry,
                                    onClose: { setHeader() }
                                )
                            } label: {
                                ChapterCardView(viewModel: chapter.progressViewModel)
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
                                isDisabled: true
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

private extension IncorrectAnswerChapterView {
    func setHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "◀ 不正解だった問題",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "不正解復習（\(unit.unit.title)）"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "xmark.circle")
                .font(.largeTitle)
                .foregroundColor(.themeIncorrect)
            Text("この単元で不正解だった章はまだありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    IncorrectAnswerChapterView(
        unit: IncorrectAnswerView.UnitEntry(
            id: "unit1",
            unitId: "unit1",
            unit: QuizMetadata(version: "1", file: "", title: "サンプル単元", subtitle: "Sample", total: 0),
            chapters: []
        ),
        onClose: {}
    )
    .environmentObject(MainViewState())
}
