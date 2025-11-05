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
            LazyVStack(spacing: 16) {
                if viewModel.correctChapters.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.correctChapters) { chapter in
                        NavigationLink {
                            CorrectAnswerPlayView(
                                unit: unit,
                                chapter: chapter.entry,
                                onSelect: { question in
                                onClose: { setHeader() }
                            )
                        } label: {
                            chapterCard(for: chapter)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                SoundManager.shared.play(.tap)
                            }
                        )
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

    func chapterCard(for chapter: CorrectAnswerChapterViewModel.CorrectChapter) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(chapter.title)
                .font(.headline)
                .foregroundColor(.themeTextPrimary)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("正解済み \(chapter.correctCount) 問")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeCorrect)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
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
                .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 8)
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
