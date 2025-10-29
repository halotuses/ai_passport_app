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
    @ObservedResults(
        BookmarkObject.self,
        where: { $0.userId == ReviewView.userId && $0.isBookmarked == true },
        sortDescriptor: SortDescriptor(keyPath: "updatedAt", ascending: false)
    ) private var bookmarks
    @ObservedResults(
        QuestionProgressObject.self,
        sortDescriptor: SortDescriptor(keyPath: "updatedAt", ascending: false)
    ) private var progresses

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
        .background(Color.themeBase.ignoresSafeArea())
        .onAppear {
            mainViewState.setHeader(title: "復習", backButton: .toHome)
        }
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
                 summaryCard(title: "未回答", value: unansweredProgresses.count, icon: "questionmark.circle.fill", tint: .themeTextSecondary)
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
                 emptyMessage: "ブックマークした問題はまだありません。"
             )

             ReviewCategorySection(
                 title: "正解した問題",
                 subtitle: "正解できた問題も定期的に復習して定着させましょう。",
                 iconName: "checkmark.circle.fill",
                 tintColor: .themeCorrect,
                 items: correctProgresses.map { ReviewItem(progress: $0, context: .status(.correct)) },
                 emptyMessage: "まだ正解した問題はありません。"
             )

             ReviewCategorySection(
                 title: "不正解だった問題",
                 subtitle: "苦手な問題を重点的に振り返りましょう。",
                 iconName: "xmark.circle.fill",
                 tintColor: .themeIncorrect,
                 items: incorrectProgresses.map { ReviewItem(progress: $0, context: .status(.incorrect)) },
                 emptyMessage: "不正解の問題はありません。"
             )

             ReviewCategorySection(
                 title: "未回答の問題",
                 subtitle: "まだ挑戦できていない問題を確認してみましょう。",
                 iconName: "questionmark.circle.fill",
                 tintColor: .themeTextSecondary,
                 items: unansweredProgresses.map { ReviewItem(progress: $0, context: .status(.unanswered)) },
                 emptyMessage: "未回答の問題はありません。"
             )
         }
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

     var unansweredProgresses: [QuestionProgress] {
         progresses
             .filter { $0.status == .unanswered }
             .map(QuestionProgress.init(object:))
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

private struct ReviewCategorySection: View {
    let title: String
    let subtitle: String
    let iconName: String
    let tintColor: Color
    let items: [ReviewItem]
    let emptyMessage: String

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
                        ReviewQuestionRow(item: item)
                    }
                }
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
}
