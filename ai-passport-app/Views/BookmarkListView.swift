import SwiftUI
import RealmSwift

struct BookmarkListView: View {
    @ObservedResults(QuestionProgressObject.self, where: { $0.isBookmarked == true }) var bookmarks

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                VStack(spacing: 12) {
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
                    ForEach(bookmarks.sorted(by: { $0.quizId < $1.quizId }), id: \.quizId) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.questionText ?? "問題文なし")
                                .font(.headline)
                                .foregroundColor(.themeTextPrimary)
                                .lineLimit(3)
                            if let answer = correctAnswerText(for: item) {
                                Text("正解: \(answer)")
                                    .font(.subheadline)
                                    .foregroundColor(.themeTextSecondary)
                            }
                            if !item.unitIdentifier.isEmpty || !item.chapterIdentifier.isEmpty {
                                Text(locationText(for: item))
                                    .font(.caption)
                                    .foregroundColor(.themeTextSecondary.opacity(0.8))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color.themeBase.ignoresSafeArea())
    }
}

private extension BookmarkListView {
    func correctAnswerText(for item: QuestionProgressObject) -> String? {
        guard let index = item.correctChoiceIndex else { return nil }
        let choices = Array(item.choiceTexts)
        guard choices.indices.contains(index) else { return nil }
        return choices[index]
    }

    func locationText(for item: QuestionProgressObject) -> String {
        switch (item.unitIdentifier.isEmpty, item.chapterIdentifier.isEmpty) {
        case (false, false):
            return "\(item.unitIdentifier) / \(item.chapterIdentifier)"
        case (false, true):
            return item.unitIdentifier
        case (true, false):
            return item.chapterIdentifier
        case (true, true):
            return item.quizId
        }
    }
}
