import SwiftUI
import RealmSwift

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
    @EnvironmentObject private var router: NavigationRouter
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
    @State private var isNavigatingToQuiz = false
    @State private var navigationErrorMessage: String? = nil
    @State private var activeUnitSelectionCategory: ReviewCategory? = nil
    @State private var isShowingUnitSelection = false
    @State private var activePlayCategory: ReviewCategory? = nil
    @State private var activePlaySelection: ReviewUnitListView.Selection? = nil
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
        
        .alert(
            "復習を開始できませんでした",
            isPresented: Binding(
                get: { navigationErrorMessage != nil },
                set: { value in
                    if !value {
                        navigationErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: {
                if let navigationErrorMessage {
                    Text(navigationErrorMessage)
                }
            }
        )
    }
}

private extension ReviewView {
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                summaryCard(title: "ブックマーク", value: bookmarks.count, icon: "bookmark.fill", tint: .themeAccent)
                summaryCard(title: "正解", value: correctProgresses.count, icon: "checkmark.circle.fill", tint: .themeCorrect)
                summaryCard(title: "不正解", value: incorrectProgresses.count, icon: "xmark.circle.fill", tint: .themeIncorrect)
            }
        }
    }
    var reviewSections: some View {
        VStack(spacing: 24) {
            ReviewCategorySection(
                title: "ブックマーク",
                subtitle: "後で見返したい問題を集めています。",
                iconName: "bookmark.fill",
                tintColor: .themeAccent,
                items: bookmarkItems,
                emptyMessage: "ブックマークした問題はまだありません。",
                isInteractionDisabled: isNavigatingToQuiz,
                onSelect: handleItemSelection,
                footer: bookmarkSectionFooter
            )

            ReviewCategoryButtonSection(
                title: "正解した問題",
                subtitle: "正解できた問題も定期的に復習して定着させましょう。",
                iconName: "checkmark.circle.fill",
                tintColor: .themeCorrect,
                count: correctProgresses.count,
                emptyMessage: "まだ正解した問題はありません。",
                buttonTitle: "単元を選択する",
                buttonSubtitle: "正解済み \(correctProgresses.count) 問",
                isInteractionDisabled: isNavigatingToQuiz,
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
                isInteractionDisabled: isNavigatingToQuiz,
                action: {
                    guard !incorrectProgresses.isEmpty else { return }
                    SoundManager.shared.play(.tap)
                    activeUnitSelectionCategory = .incorrect
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
    var unitSelectionNavigationLink: some View {
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
            destination: {
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
            ),
            label: {
                EmptyView()
            }
        )
        .hidden()
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
                        if let category = activePlayCategory, let selection = activePlaySelection {
                            ReviewPlayView(category: category, selection: selection) {
                                isShowingPlayView = false
                                activePlayCategory = nil
                                activePlaySelection = nil
                                isShowingUnitSelection = false
                                activeUnitSelectionCategory = nil
                                mainViewState.setHeader(title: "復習", backButton: .toHome)
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
    
    var bookmarkItems: [ReviewItem] {
        let progressLookup = Dictionary(uniqueKeysWithValues: progresses.map { ($0.quizId, QuestionProgress(object: $0)) })
        return bookmarks.map { bookmark in
            let progress = progressLookup[bookmark.quizId]
            return ReviewItem(
                id: bookmark.quizId,
                progress: progress,
                context: .bookmark,
                timestamp: bookmark.updatedAt
            )
        }
    }


       var bookmarkSectionFooter: AnyView? {
           guard !bookmarks.isEmpty else { return nil }
           let button = Button {
               guard !isNavigatingToQuiz else { return }
               SoundManager.shared.play(.tap)
               activeUnitSelectionCategory = .bookmark
                      isShowingUnitSelection = true
           } label: {
               HStack(alignment: .center, spacing: 12) {
                   Image(systemName: "arrowshape.turn.up.right.fill")
                       .font(.title3.weight(.semibold))
                       .foregroundColor(.themeAccent)
                       .frame(width: 44, height: 44)
                       .background(Color.themeAccent.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                   VStack(alignment: .leading, spacing: 4) {
                       Text("単元を選択する")
                           .font(.headline)
                           .foregroundColor(.themeTextPrimary)
                       Text("ブックマーク \(bookmarks.count) 問")
                           .font(.subheadline)
                           .foregroundColor(.themeTextSecondary)
                   }

                   Spacer()

                   Image(systemName: "chevron.right")
                       .font(.headline.weight(.semibold))
                       .foregroundColor(.themeTextSecondary)
               }
               .padding(.horizontal, 16)
               .padding(.vertical, 14)
               .background(
                   RoundedRectangle(cornerRadius: 18, style: .continuous)
                       .fill(Color.themeSurfaceElevated)
               )
               .overlay(
                   RoundedRectangle(cornerRadius: 18, style: .continuous)
                       .stroke(Color.themeAccent.opacity(0.12), lineWidth: 1)
               )
           }
           .buttonStyle(.plain)
           .disabled(isNavigatingToQuiz)

           return AnyView(button)
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

    func summaryCard(title: String, value: Int, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.15), in: Circle())

                Spacer()

                Text("\(value)")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.themeTextPrimary)
            }

            Text(title)
                .font(.footnote)
                .foregroundColor(.themeTextSecondary)

        }
        .padding(20)
        .frame(maxWidth: .infinity)
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
    func handleItemSelection(_ item: ReviewItem) {
        guard !isNavigatingToQuiz else { return }
        guard let context = item.makeNavigationContext() else {
            navigationErrorMessage = "問題の位置情報を取得できませんでした。"
            return
        }

        SoundManager.shared.play(.tap)
        isNavigatingToQuiz = true
        navigationErrorMessage = nil

        Task {
            await navigateToQuiz(context)
            await MainActor.run {
                isNavigatingToQuiz = false
            }
        }
    }
    
    func navigateToQuiz(_ context: ReviewItem.NavigationContext) async {
        guard let metadata = await fetchMetadataIfNeeded() else {
            await presentNavigationError("コンテンツ情報を取得できませんでした。")
            return
        }

        guard let unit = metadata[context.unitId] else {
            await presentNavigationError("対応する単元が見つかりませんでした。")
            return
        }

        guard let chapters = await fetchChaptersIfNeeded(for: context.unitId, filePath: unit.file) else {
            await presentNavigationError("章の情報を取得できませんでした。")
            return
        }

        guard let chapter = chapters.first(where: { $0.id == context.chapterId }) else {
            await presentNavigationError("対応する章が見つかりませんでした。")
            return
        }

        await MainActor.run {
            router.reset()
            mainViewState.enterUnitSelection()
            mainViewState.selectedUnitKey = context.unitId
            mainViewState.selectedUnit = unit
            progressManager.chapterListViewModel.fetchChapters(forUnitId: context.unitId, filePath: unit.file)
            progressManager.quizViewModel.prepareForReviewNavigation(initialQuestionIndex: context.questionIndex)
            mainViewState.selectedChapter = chapter
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

    func presentNavigationError(_ message: String) async {
        await MainActor.run {
            navigationErrorMessage = message
        }
    }
}

private struct ReviewItem: Identifiable {
    enum Context {
        case bookmark
        case status(QuestionStatus)
    }

    let id: String
    let progress: QuestionProgress?
    let context: Context
    let timestamp: Date?

    init(progress: QuestionProgress, context: Context) {
        self.id = progress.quizId
        self.progress = progress
        self.context = context
        self.timestamp = progress.updatedAt
    }

    init(id: String, progress: QuestionProgress?, context: Context, timestamp: Date?) {
        self.id = id
        self.progress = progress
        self.context = context
        self.timestamp = timestamp
    }
}
private extension ReviewItem {
    struct NavigationContext {
        let unitId: String
        let chapterId: String
        let questionIndex: Int
    }

    func makeNavigationContext() -> NavigationContext? {
        let identifier = progress?.quizId ?? id
        guard let parsed = QuizIdentifierParser.parse(identifier) else {
            return nil
        }

        let unitId: String
        if let storedUnit = progress?.unitId, !storedUnit.isEmpty {
            unitId = storedUnit
        } else {
            unitId = parsed.unitId
        }

        let chapterId: String
        if let storedChapter = progress?.chapterIdentifier, !storedChapter.isEmpty {
            chapterId = storedChapter
        } else {
            chapterId = parsed.chapterId
        }

        guard let questionIndex = parsed.questionIndex else { return nil }

        return NavigationContext(
            unitId: unitId,
            chapterId: chapterId,
            questionIndex: max(questionIndex, 0)
        )
    }
}
private struct ReviewCategorySection: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let items: [ReviewItem]
    let emptyMessage: String
    let isInteractionDisabled: Bool
    let onSelect: (ReviewItem) -> Void
    let footer: AnyView?

      init(
          title: String,
          subtitle: String,
          iconName: String,
          tintColor: Color,
          items: [ReviewItem],
          emptyMessage: String,
          isInteractionDisabled: Bool,
          onSelect: @escaping (ReviewItem) -> Void,
          footer: AnyView? = nil
      ) {
          self.title = title
          self.subtitle = subtitle
          self.iconName = iconName
          self.tintColor = tintColor
          self.items = items
          self.emptyMessage = emptyMessage
          self.isInteractionDisabled = isInteractionDisabled
          self.onSelect = onSelect
          self.footer = footer
      }

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

                Text("\(items.count)")
                    .font(.headline)
                    .foregroundColor(tintColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tintColor.opacity(0.12), in: Capsule())
            }

            if items.isEmpty {
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
                VStack(spacing: 16) {
                    ForEach(items) { item in
                        Button {
                            onSelect(item)
                        } label: {
                            ReviewQuestionRow(item: item)
                        }
                        .buttonStyle(.plain)
                        .disabled(isInteractionDisabled)
                    }
                }
            }
            if let footer {
                footer
                    .padding(.top, 8)
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
private struct ReviewQuestionRow: View {
    let item: ReviewItem

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(questionTitle)
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                badge
            }

            if let location = item.progress?.displayLocation, !location.isEmpty {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }

            answerSection

            if let updated = item.timestamp {
                Text("更新日: \(Self.dateFormatter.string(from: updated))")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary.opacity(0.9))
            }
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

    private var questionTitle: String {
        if let text = item.progress?.questionText, !text.isEmpty {
            return text
        }
        return "問題ID: \(item.progress?.quizId ?? item.id)"
    }

    @ViewBuilder
    private var badge: some View {
        switch item.context {
        case .bookmark:
            Text("ブックマーク")
                .font(.caption.weight(.semibold))
                .foregroundColor(.themeAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.themeAccent.opacity(0.15), in: Capsule())
        case .status(let status):
            Text(status.displayLabel)
                .font(.caption.weight(.semibold))
                .foregroundColor(status.foregroundColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(status.backgroundColor, in: Capsule())
        }
    }

    @ViewBuilder
    private var answerSection: some View {
        switch item.context {
        case .bookmark:
            bookmarkAnswerSection
        case .status(let status):
            statusAnswerSection(for: status)
        }
    }

    @ViewBuilder
    private var bookmarkAnswerSection: some View {
        if let progress = item.progress {
            VStack(alignment: .leading, spacing: 8) {
                Text("ステータス: \(progress.status.displayLabel)")
                    .font(.subheadline)
                    .foregroundColor(progress.status == .correct ? .themeCorrect : progress.status == .incorrect ? .themeIncorrect : .themeTextSecondary)
                statusAnswerSection(for: progress.status)
            }
        } else {
            Text("この問題の学習データはまだありません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
    }

    @ViewBuilder
    private func statusAnswerSection(for status: QuestionStatus) -> some View {
        switch status {
        case .correct, .incorrect:
            VStack(alignment: .leading, spacing: 8) {
                if let selected = item.progress?.selectedChoiceText {
                    LabeledContent("あなたの回答", value: selected)
                        .font(.subheadline)
                        .foregroundColor(status == .correct ? .themeCorrect : .themeIncorrect)
                }

                if let correct = item.progress?.correctChoiceText, status == .incorrect {
                    LabeledContent("正しい答え", value: correct)
                        .font(.subheadline)
                        .foregroundColor(.themeCorrect)
                }
            }
        case .unanswered:
            Text("まだ回答していません。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
        }
    }
}
#Preview {
    ReviewView()
        .environmentObject(MainViewState())
        .environmentObject(NavigationRouter())
        .environmentObject(ProgressManager())
}
