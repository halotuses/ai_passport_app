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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView("読み込み中…")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 48)
                } else if viewModel.hasError {
                    errorState
                } else if viewModel.units.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        ForEach(viewModel.units) { unit in
                            unitSelectionButton(unit)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.loadIfNeeded() }
        .onAppear(perform: configureHeader)
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
    
    func unitSelectionButton(_ unit: ReviewUnitListViewModel.ReviewUnit) -> some View {
        let isDisabled = !unit.hasReviewTargets
        
        return Button {
            SoundManager.shared.play(.tap)
            selectedUnit = unit
            isShowingChapterList = true
        } label: {
            unitRowView(unit: unit, isDisabled: isDisabled)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
    
    func unitRowView(unit: ReviewUnitListViewModel.ReviewUnit, isDisabled: Bool) -> some View {
        let total = unit.reviewCount
        
        return HStack(spacing: 16) {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(isDisabled ? 0.4 : 1.0)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unit.unitId). \(unit.unit.title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                    .opacity(isDisabled ? 0.65 : 1.0)
                
                if !unit.unit.subtitle.isEmpty {
                    Text(unit.unit.subtitle)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.themeTextSecondary)
                        .opacity(isDisabled ? 0.5 : 1.0)
                }
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.themeSecondary.opacity(0.3),
                                Color.themeMain.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Text("\(total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
            }
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .overlay(disabledOverlay(cornerRadius: 18, isDisabled: isDisabled))
        .opacity(isDisabled ? 0.55 : 1.0)
    }
    
    @ViewBuilder
    private func disabledOverlay(cornerRadius: CGFloat, isDisabled: Bool) -> some View {
        if isDisabled {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.04))
        }
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
}
