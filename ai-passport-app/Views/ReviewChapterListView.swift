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
            let progressViewModel = ReviewChapterProgressViewModel(
                chapter: chapter.chapter,
                questions: chapter.questions,
                wordPair: chapter.chapter.wordPair
            )
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
        .onChange(of: mainViewState.isOnHome) { isOnHome in
            guard isOnHome else { return }
            handleExternalDismissal()
        }
        .onChange(of: mainViewState.isShowingReview) { isShowingReview in
            guard !isShowingReview else { return }
            handleExternalDismissal()
        }
    }
}

private extension ReviewChapterListView {
    func handleExternalDismissal() {
        guard !didTriggerExternalDismissal else { return }
        didTriggerExternalDismissal = true
        dismiss()
        onClose()
    }
    func configureHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            dismiss()
            onClose()
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
                    isShowingQuestionList = false
                    DispatchQueue.main.async {
                        onSelect(selection)
                    }
                },
                onClose: {
                    isShowingQuestionList = false
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
        let progressViewModel: ReviewChapterProgressViewModel

        var id: String { chapter.id }
    }
}

@MainActor
final class ReviewChapterProgressViewModel: ObservableObject, Identifiable, ChapterProgressDisplayable {
    let id: String
    let chapter: ChapterMetadata
    let wordPair: ChapterMetadata.WordPair?

    @Published private(set) var correctCount: Int
    @Published private(set) var answeredCount: Int
    @Published private(set) var totalQuestions: Int
    @Published private(set) var accuracyRate: Double

    init(
        chapter: ChapterMetadata,
        questions: [ReviewUnitListViewModel.ReviewChapter.ReviewQuestion],
        wordPair: ChapterMetadata.WordPair? = nil
    ) {
        self.id = chapter.id
        self.chapter = chapter
        self.wordPair = wordPair ?? chapter.wordPair

        let correct = questions.filter { $0.progress.status == .correct }.count
        let answered = questions.filter { $0.progress.status.isAnswered }.count
        let total = questions.count

        self.correctCount = correct
        self.answeredCount = answered
        self.totalQuestions = total
        if answered > 0 {
            self.accuracyRate = min(max(Double(correct) / Double(answered), 0), 1)
        } else {
            self.accuracyRate = 0
        }
    }
}
