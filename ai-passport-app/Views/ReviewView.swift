import SwiftUI
@preconcurrency import RealmSwift

/// 復習機能のメイン画面
struct ReviewView: View {
    private static let userId: String = {
        if let stored = UserDefaults.standard.string(forKey: QuizViewModel.bookmarkUserIdKey) {
            return stored
        }
        let newValue = UUID().uuidString
        UserDefaults.standard.set(newValue, forKey: QuizViewModel.bookmarkUserIdKey)
        return newValue
    }()
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var progressManager: ProgressManager
    @ObservedResults(
        BookmarkObject.self,
        where: { $0.userId == ReviewView.userId && $0.isBookmarked == true },
        sortDescriptor: SortDescriptor(keyPath: "updatedAt", ascending: false)
    ) private var bookmarks
    @ObservedResults(
        QuestionProgressObject.self,
        sortDescriptor: SortDescriptor(keyPath: "updatedAt", ascending: false)
    ) private var progresses
    @State private var metadataCache: QuizMetadataMap? = nil
    @State private var chapterListCache: [String: [ChapterMetadata]] = [:]
    @State private var activeUnitSelectionCategory: ReviewCategory? = nil
    @State private var isShowingUnitSelection = false
    @State private var activePlayCategory: ReviewCategory? = nil
    @State private var activePlaySelection: ReviewUnitSelection? = nil
    @State private var isShowingPlayView = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                headerSection
                summarySection
                reviewSections
            }
            .frame(maxWidth: 560)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(reviewNavigationLinks)
        .onAppear {
            mainViewState.setHeader(title: "復習", backButton: .toHome)
        }
        .onChange(of: mainViewState.isShowingReview) { isShowing in
            if !isShowing && !mainViewState.isSuspendingReviewForBookmarks {
                resetNavigationState()
            }
        }
        .onChange(of: mainViewState.isOnHome) { isOnHome in
            if isOnHome {
                resetNavigationState()
            }
        }
    }
}

private extension ReviewView {
    func resetNavigationState() {
        isShowingUnitSelection = false
        activeUnitSelectionCategory = nil
        isShowingPlayView = false
        activePlayCategory = nil
        activePlaySelection = nil
    }
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("復習を始めましょう")
                .font(.title2.weight(.semibold))
                .foregroundColor(.themeTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("ブックマークや学習結果から、復習したい問題をまとめて確認できます。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("学習サマリー")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            summaryStatsRow
        }
    }
    var reviewSections: some View {
        VStack(spacing: 24) {
            ReviewCategoryButtonSection(
                title: "正解した問題",
                subtitle: "正解できた問題も定期的に復習して定着させましょう。",
                iconName: "checkmark.circle.fill",
                tintColor: .themeCorrect,
                count: correctProgresses.count,
                emptyMessage: "まだ正解した問題はありません。",
                buttonTitle: "単元を選択する",
                buttonSubtitle: "正解済み \(correctProgresses.count) 問",
                isInteractionDisabled: false,
                action: {
                    guard !correctProgresses.isEmpty else { return }
                    SoundManager.shared.play(.tap)
                    activeUnitSelectionCategory = .correct
                    isShowingUnitSelection = true
                }
            )
            
            ReviewCategoryButtonSection(
                title: "不正解だった問題",
                subtitle: "苦手な問題を重点的に振り返りましょう。",
                iconName: "xmark.circle.fill",
                tintColor: .themeIncorrect,
                count: incorrectProgresses.count,
                emptyMessage: "不正解の問題はありません。",
                buttonTitle: "単元を選択する",
                buttonSubtitle: "不正解 \(incorrectProgresses.count) 問",
                isInteractionDisabled: false,
                action: {
                    guard !incorrectProgresses.isEmpty else { return }
                    SoundManager.shared.play(.tap)
                    activeUnitSelectionCategory = .incorrect
                    isShowingUnitSelection = true
                }
            )
        ReviewCategoryButtonSection(
            title: "ブックマーク",
            subtitle: "後で見返したい問題を集めています。",
            iconName: "bookmark.fill",
            tintColor: .themeAccent,
            count: bookmarks.count,
            emptyMessage: "ブックマークした問題はまだありません。",
            buttonTitle: "単元を選択する",
            buttonSubtitle: "ブックマーク \(bookmarks.count) 問",
            isInteractionDisabled: false,
            action: {
                guard !bookmarks.isEmpty else { return }
                SoundManager.shared.play(.tap)
                activeUnitSelectionCategory = .bookmark
                isShowingUnitSelection = true
            }
        )
        }
    }
    
    @ViewBuilder
    var reviewNavigationLinks: some View {
        ZStack {
            unitSelectionNavigationLink
            playNavigationLink
        }
    }
    
    
    @ViewBuilder
    private var unitSelectionNavigationLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { isShowingUnitSelection },
                set: { newValue in
                    if !newValue {
                        isShowingUnitSelection = false
                        activeUnitSelectionCategory = nil
                    }
                }
            ),
            destination: { selectedUnitView },
            label: {
                EmptyView()
            }
            
        )
        .hidden()
    }
    
    @ViewBuilder
    private var selectedUnitView: some View {
        if let category = activeUnitSelectionCategory {
            ReviewUnitListView(
                progresses: progresses(for: category),
                metadataProvider: { await fetchMetadataIfNeeded() },
                chapterListProvider: { unitId, filePath in
                    await fetchChaptersIfNeeded(for: unitId, filePath: filePath)
                },
                shouldInclude: { progress in
                    shouldInclude(progress, for: category)
                },
                headerTitle: category.unitSelectionHeader,
                onSelect: { selection in
                    activePlayCategory = category
                    activePlaySelection = selection
                    isShowingPlayView = true
                },
                onClose: {
                    isShowingUnitSelection = false
                    activeUnitSelectionCategory = nil
                    mainViewState.setHeader(title: "復習", backButton: .toHome)
                }
            )
        } else {
            EmptyView()
        }
    }
    
    @ViewBuilder
    var playNavigationLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { isShowingPlayView },
                set: { newValue in
                    if !newValue {
                        isShowingPlayView = false
                        activePlayCategory = nil
                        activePlaySelection = nil
                    }
                }
            ),
            destination: {
                if let category = activePlayCategory,
                   let selection = activePlaySelection {
                    ReviewPlayView(category: category, selection: selection) {
                        isShowingPlayView = false
                        activePlayCategory = nil
                        activePlaySelection = nil
                    }
                } else {
                    EmptyView()
                }
            },
            label: {
                EmptyView()
            }
        )
        .hidden()
    }
    

    var correctProgresses: [QuestionProgress] {
        progresses
            .filter { $0.status == .correct }
            .map(QuestionProgress.init(object:))
    }
    
    var incorrectProgresses: [QuestionProgress] {
        progresses
            .filter { $0.status == .incorrect }
            .map(QuestionProgress.init(object:))
    }
    func progresses(for category: ReviewCategory) -> [QuestionProgress] {
        switch category {
        case .bookmark:
            return progressManager.bookmarkedProgresses(for: ReviewView.userId)
        case .correct:
            return correctProgresses
        case .incorrect:
            return incorrectProgresses
        }
    }
    
    func shouldInclude(_ progress: QuestionProgress, for category: ReviewCategory) -> Bool {
        switch category {
        case .bookmark:
            return true
        case .correct:
            return progress.status == .correct
        case .incorrect:
            return progress.status == .incorrect
        }
    }
    
    var summaryStatsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            ForEach(summaryItems) { item in
                summaryStat(item)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var summaryItems: [ReviewSummaryItem] {
        [
            .init(title: "正解", value: correctProgresses.count, unit: "問", icon: "checkmark.circle.fill", tint: .themeCorrect),
            .init(title: "不正解", value: incorrectProgresses.count, unit: "問", icon: "xmark.circle.fill", tint: .themeIncorrect),
            .init(title: "ブックマーク", value: bookmarks.count, unit: "問", icon: "bookmark.fill", tint: .themeAccent)
        ]
    }

    private func summaryStat(_ item: ReviewSummaryItem) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.tint.opacity(0.18))
                    .frame(width: 42, height: 42)
                Image(systemName: item.icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(item.tint)
            }
            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.themeTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(item.value)")
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(.themeTextPrimary)
                Text(item.unit)
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.themeSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private struct ReviewSummaryItem: Identifiable, Equatable {
        let id: String
        let title: String
        let value: Int
        let unit: String
        let icon: String
        let tint: Color

        init(title: String, value: Int, unit: String, icon: String, tint: Color) {
            self.id = title
            self.title = title
            self.value = value
            self.unit = unit
            self.icon = icon
            self.tint = tint
        }
    }
    
    func fetchMetadataIfNeeded() async -> QuizMetadataMap? {
        if let metadataCache {
            return metadataCache
        }
        
        let metadata = await withCheckedContinuation { continuation in
            NetworkManager.fetchMetadata { result in
                continuation.resume(returning: result)
            }
        }
        
        if let metadata {
            await MainActor.run {
                metadataCache = metadata
            }
        }
        
        return metadata
    }
    
    func fetchChaptersIfNeeded(for unitId: String, filePath: String) async -> [ChapterMetadata]? {
        if let cached = chapterListCache[unitId] {
            return cached
        }
        
        let chapters = await withCheckedContinuation { continuation in
            NetworkManager.fetchChapterList(from: Constants.url(filePath)) { chapterList in
                continuation.resume(returning: chapterList?.chapters)
            }
        }
        
        guard let chapters else { return nil }
        
        await MainActor.run {
            chapterListCache[unitId] = chapters
        }
        
        return chapters
    }
    

}
private struct ReviewCategoryButtonSection: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let count: Int
    let emptyMessage: String
    let buttonTitle: String
    let buttonSubtitle: String
    let isInteractionDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(tintColor)
                    .frame(width: 44, height: 44)
                    .background(tintColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                
                Spacer()
                
                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tintColor.opacity(0.12), in: Capsule())
            }
            
            if count == 0 {
                Text(emptyMessage)
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.themeSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                    )
            } else {
                Button(action: action) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(buttonTitle)
                                .font(.headline)
                                .foregroundColor(.themeTextPrimary)
                            Text(buttonSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.themeTextSecondary)
                        }
                        
                        Spacer(minLength: 12)
                        
                        Image(systemName: "chevron.right")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(.themeTextSecondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.themeSurfaceElevated)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isInteractionDisabled)
                .opacity(isInteractionDisabled ? 0.6 : 1)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.themeSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 18, x: 0, y: 12)
    }
}

#Preview {
    ReviewView()
        .environmentObject(MainViewState())
        .environmentObject(NavigationRouter())
        .environmentObject(ProgressManager())
}
