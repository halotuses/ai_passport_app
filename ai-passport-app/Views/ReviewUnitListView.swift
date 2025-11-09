import SwiftUI

struct ReviewUnitListView: View {
    
    @StateObject private var viewModel: ReviewUnitListViewModel
    private let onSelect: @Sendable (ReviewUnitSelection) -> Void
    private let onClose: () -> Void
    private let headerTitle: String
    @State private var selectedUnit: ReviewUnitListViewModel.ReviewUnit? = nil
    @State private var isShowingChapterList = false
    
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss
    
    init(
        progresses: [QuestionProgress],
        metadataProvider: @escaping () async -> QuizMetadataMap?,
        chapterListProvider: @escaping (String, String) async -> [ChapterMetadata]?,
        shouldInclude: @escaping (QuestionProgress) -> Bool = { _ in true },
        headerTitle: String = "復習用単元選択",
        onSelect: @escaping @Sendable (ReviewUnitSelection) -> Void,        onClose: @escaping () -> Void
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
                        VStack(spacing: 16) {
                            ForEach(viewModel.units) { unit in
                                unitSection(unit)
                            }
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
        .background(navigationLinks)
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
        Button {
            SoundManager.shared.play(.tap)
            selectedUnit = unit
            isShowingChapterList = true
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(unit.unitId). \(unit.unit.title)")
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !unit.unit.subtitle.isEmpty {
                        Text(unit.unit.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.themeTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                HStack(spacing: 12) {
                    labelCapsule(text: "復習対象 \(unit.reviewCount) 問", systemImage: "doc.text")
                    labelCapsule(text: "章 \(unit.chapterCount)", systemImage: "list.number")
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.themeTextSecondary)
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
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    var navigationLinks: some View {
        NavigationLink(
            isActive: Binding(
                get: { isShowingChapterList },
                set: { newValue in
                    if !newValue {
                        isShowingChapterList = false
                        selectedUnit = nil
                        configureHeader()
                    }
                }
            ),
            destination: { chapterSelectionView },
            label: {
                EmptyView()
            }
        )
        .hidden()
    }
    
    @ViewBuilder
    var chapterSelectionView: some View {
        if let unit = selectedUnit {
            ReviewChapterListView(
                unit: unit,
                headerTitle: headerTitle,
                onSelect: { selection in
                    isShowingChapterList = false
                    selectedUnit = nil
                    configureHeader()
                    onSelect(selection)
                },
                onClose: {
                    isShowingChapterList = false
                    selectedUnit = nil
                    configureHeader()
                }
            )
        } else {
            EmptyView()
        }
    }
    
    func labelCapsule(text: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.themeTextSecondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.themeSurface)
                .overlay(
                    Capsule()
                        .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
