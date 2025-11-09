import SwiftUI

struct ReviewUnitListView: View {

    @StateObject private var viewModel: ReviewUnitListViewModel
    private let onSelect: @Sendable (ReviewUnitSelection) -> Void
    private let onClose: () -> Void
    private let headerTitle: String

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

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

    ScrollView(showsIndicators: false) {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView("読み込み中…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else if viewModel.hasError {
                    errorState
                } else if viewModel.units.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.units) { unit in
                        unitSection(unit)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.themeBase)
        .task { await viewModel.loadIfNeeded() }
        .onAppear(perform: configureHeader)
    }
}

private extension ReviewUnitListView {
    func configureHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        mainViewState.setHeader(title: headerTitle, backButton: backButton)
    }
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
        .background(stateBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
        .background(stateBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var stateBackground: some ShapeStyle {
        LinearGradient(
            colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func unitSection(_ unit: ReviewUnitListViewModel.ReviewUnit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unit.unitId). \(unit.unit.title)")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                if !unit.unit.subtitle.isEmpty {
                    Text(unit.unit.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                Text("復習対象 \(unit.reviewCount) 問")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }

            VStack(spacing: 12) {
                ForEach(unit.chapters) { chapter in
                    Button {
                        SoundManager.shared.play(.tap)
                        handleSelection(chapter, in: unit)
                    } label: {
                        chapterRow(chapter)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 14, x: 0, y: 10)
    }

    func chapterRow(_ chapter: ReviewUnitListViewModel.ReviewChapter) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text("復習対象 \(chapter.reviewCount) 問")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            countBubble(total: chapter.reviewCount)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurface, Color.themeSurfaceAlt.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.8), radius: 10, x: 0, y: 6)
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
}
