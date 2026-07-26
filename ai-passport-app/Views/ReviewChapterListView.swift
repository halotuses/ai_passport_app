import SwiftUI

struct ReviewChapterListView: View {

    let unit: ReviewUnitListViewModel.ReviewUnit
    private let headerTitle: String
    private let onSelect: @Sendable (ReviewUnitSelection) -> Void
    private let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss
    @State private var chapterItems: [ReviewChapterItem]
    @State private var activeChapter: ReviewUnitListViewModel.ReviewChapter? = nil
    @State private var isShowingQuestionList = false
    @State private var didTriggerExternalDismissal = false

    init(
        unit: ReviewUnitListViewModel.ReviewUnit,
        headerTitle: String,
        onSelect: @escaping @Sendable (ReviewUnitSelection) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.headerTitle = headerTitle
        self.onSelect = onSelect
        self.onClose = onClose
        let items = unit.chapters.map { chapter -> ReviewChapterItem in
            // 復習対象だけでなく、通常の章選択と同じ保存済み学習進捗を表示する。
            let progressViewModel = ChapterProgressViewModel(
                unitId: unit.unitId,
                chapter: chapter.chapter
            )
            Self.loadTotalQuestionCount(for: chapter.chapter, into: progressViewModel)
            return ReviewChapterItem(chapter: chapter, progressViewModel: progressViewModel)
        }
        _chapterItems = State(initialValue: items)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if chapterItems.isEmpty {
                    emptyState
                } else {
                    ForEach(chapterItems) { item in
                        Button {
                            guard item.chapter.hasReviewTargets else { return }
                            SoundManager.shared.play(.tap)
                            activeChapter = item.chapter
                            isShowingQuestionList = true
                        } label: {
                            ChapterCardView(
                                viewModel: item.progressViewModel,
                                isDisabled: !item.chapter.hasReviewTargets
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!item.chapter.hasReviewTargets)
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: configureHeader)
        .background(questionSelectionNavigationLink)
        .onChange(of: mainViewState.isOnHome) { _, isOnHome in
            guard isOnHome else { return }
            handleExternalDismissal()
        }
        .onChange(of: mainViewState.isShowingReview) { _, isShowingReview in
            guard !isShowingReview else { return }
            if mainViewState.isSuspendingReviewForBookmarks { return }
            handleExternalDismissal()
        }
        .onChange(of: mainViewState.navigationResetToken) { _, _ in
            handleExternalDismissal()
        }
    }
}

private extension ReviewChapterListView {
    static func loadTotalQuestionCount(for chapter: ChapterMetadata, into viewModel: ChapterProgressViewModel) {
        NetworkManager.fetchQuizList(from: Constants.url(chapter.file)) { quizList in
            let count = quizList?.questions.count ?? 0
            Task { @MainActor in
                viewModel.updateTotalQuestions(count)
            }
        }
    }
    func handleExternalDismissal() {
        guard !didTriggerExternalDismissal else { return }
        didTriggerExternalDismissal = true
        onClose()
        dismiss()
    }
    func configureHeader() {
        guard !mainViewState.isOnHome else { return }
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            onClose()
            dismiss()
        }
        let title = "\(headerTitle) / \(unit.unit.title)"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book")
                .font(.largeTitle)
                .foregroundColor(.themeTextSecondary)
            Text("この単元で復習する問題はありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    @ViewBuilder
    var questionSelectionNavigationLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { isShowingQuestionList },
                set: { newValue in
                    if !newValue {
                        isShowingQuestionList = false
                        activeChapter = nil
                        configureHeader()
                    } else {
                        isShowingQuestionList = true
                    }
                }
            ),
            destination: { questionSelectionView },
            label: {
                EmptyView()
            }
        )
        .hidden()
    }

    @ViewBuilder
    var questionSelectionView: some View {
        if let chapter = activeChapter {
            ReviewQuestionListView(
                unit: unit,
                chapter: chapter,
                headerTitle: headerTitle,
                onSelect: { selection in
                    DispatchQueue.main.async {
                        onSelect(selection)
                    }
                },
                onClose: {
                    isShowingQuestionList = false
                    dismiss()
                }
            )
        } else {
            EmptyView()
        }
    }
}
private extension ReviewChapterListView {
    struct ReviewChapterItem: Identifiable {
        let chapter: ReviewUnitListViewModel.ReviewChapter
        let progressViewModel: ChapterProgressViewModel

        var id: String { chapter.id }
    }
}
