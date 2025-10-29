import Foundation
import SwiftUI
import RealmSwift

struct BookmarkListView: View {
    private static let userId: String = {
        if let stored = UserDefaults.standard.string(forKey: QuizViewModel.bookmarkUserIdKey) {
            return stored
        }
        let newValue = UUID().uuidString
        UserDefaults.standard.set(newValue, forKey: QuizViewModel.bookmarkUserIdKey)
        return newValue
    }()

    @ObservedResults(
        BookmarkObject.self,
        where: { $0.userId == BookmarkListView.userId && $0.isBookmarked == true }
    ) var bookmarks
    @ObservedResults(QuestionProgressObject.self) var progresses

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                VStack(spacing: 12) {
                    bookmarkCountSummary()
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("ブックマークはまだありません。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    Section {
                        ForEach(bookmarks.sorted(by: { $0.quizId < $1.quizId })) { item in
                            bookmarkRow(for: item, progress: progress(for: item))
                        }
                    } header: {
                        bookmarkListHeader()
                    }
                    .textCase(nil)
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.themeBase.ignoresSafeArea())
    }
}

private extension BookmarkListView {
    func progress(for bookmark: BookmarkObject) -> QuestionProgressObject? {
        progresses.first(where: { $0.quizId == bookmark.quizId })
    }

    @ViewBuilder
    func bookmarkRow(for bookmark: BookmarkObject, progress: QuestionProgressObject?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(progress?.questionText ?? "問題文なし")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
                .lineLimit(3)
            if let answer = correctAnswerText(for: progress) {
                Text("正解: \(answer)")
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }
            if let location = locationText(for: progress) {
                Text(location)
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary.opacity(0.8))
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    func bookmarkListHeader() -> some View {
        HStack(alignment: .center) {
            Text("ブックマーク")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            Spacer()
            bookmarkCountBadge(for: bookmarks.count)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    func bookmarkCountSummary() -> some View {
        HStack(spacing: 12) {
            Text("ブックマーク")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)
            bookmarkCountBadge(for: bookmarks.count)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    func bookmarkCountBadge(for count: Int) -> some View {
        Text("\(count)件")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.themeAccent)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(Color.themePillBackground)
            )
    }

    func correctAnswerText(for progress: QuestionProgressObject?) -> String? {
        guard let progress, let index = progress.correctChoiceIndex else { return nil }
        let choices = Array(progress.choiceTexts)
        guard choices.indices.contains(index) else { return nil }
        return choices[index]
    }

    func locationText(for progress: QuestionProgressObject?) -> String? {
        guard let progress else { return nil }
        switch (progress.unitIdentifier.isEmpty, progress.chapterIdentifier.isEmpty) {
        case (false, false):
            return "\(progress.unitIdentifier) / \(progress.chapterIdentifier)"
        case (false, true):
            return progress.unitIdentifier
        case (true, false):
            return progress.chapterIdentifier
        case (true, true):
            return progress.quizId
        }
    }
}
