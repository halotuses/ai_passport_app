import SwiftUI

struct ReviewUnitListView: View {

    @StateObject private var viewModel: ReviewUnitListViewModel
    private let onSelect: @Sendable (ReviewUnitSelection) -> Void
    private let onClose: () -> Void
    private let headerTitle: String

    @EnvironmentObject private var mainViewState: MainViewState

    init(
        progresses: [QuestionProgress],
        metadataProvider: @escaping () async -> QuizMetadataMap?,
        chapterListProvider: @escaping (String, String) async -> [ChapterMetadata]?,
        shouldInclude: @escaping (QuestionProgress) -> Bool = { _ in true },
        headerTitle: String = "復習用章選択",
        onSelect: @escaping @Sendable (ReviewUnitSelection) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = StateObject(
            wrappedValue: ReviewUnitListViewModel(
                progresses: progresses,
                metadataProvider: metadataProvider,
                chapterListProvider: chapterListProvider,
                shouldInclude: shouldInclude
            )
        )
        self.onSelect = onSelect
        self.onClose = onClose
        self.headerTitle = headerTitle
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView().padding()
                } else if viewModel.hasError {
                    errorState
                } else if viewModel.units.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.units) { unit in
                        NavigationLink {
                            ReviewQuestionListView(
                                unit: unit,
                                onSelect: { chapter in
                                    handleSelection(chapter, in: unit)
                                },
                                onClose: handleBackToList
                            )
                        } label: {
                            unitRow(unit)
                        }
                        .buttonStyle(.plain)
                        .simultaneousGesture(TapGesture().onEnded {
                            SoundManager.shared.play(.tap)
                        })
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .task { await viewModel.loadIfNeeded() }
        .onAppear {
            let backButton = MainViewState.HeaderBackButton(
                title: "戻る",
                destination: .custom,
                action: onClose
            )
            mainViewState.setHeader(title: headerTitle, backButton: backButton)
        }
    }
}

private extension ReviewUnitListView {
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.themeTextSecondary)
            Text("復習できる章がまだありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    var errorState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.themeIncorrect)
            Text("復習用の章情報を取得できませんでした。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    func unitRow(_ unit: ReviewUnitListViewModel.ReviewUnit) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unit.unitId). \(unit.unit.title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text(unit.unit.subtitle)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            countBubble(total: unit.reviewCount)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 6)
    }

    func countBubble(total: Int) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.themeSecondary.opacity(0.3), Color.themeMain.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
            Text("\(total)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.themeTextPrimary)
        }
    }

    func handleSelection(_ chapter: ReviewUnitListViewModel.ReviewChapter, in unit: ReviewUnitListViewModel.ReviewUnit) {
        let selection = ReviewUnitSelection(
            unitId: unit.unitId,
            unit: unit.unit,
            chapter: chapter.chapter,
            initialQuestionIndex: chapter.initialQuestionIndex,
            questions: chapter.questions
        )
        onSelect(selection)
    }

    func handleBackToList() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom,
            action: onClose
        )
        mainViewState.setHeader(title: headerTitle, backButton: backButton)
    }
}
