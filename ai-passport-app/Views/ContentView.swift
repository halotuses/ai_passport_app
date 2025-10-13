import SwiftUI

/// 出題画面（読み込み → 出題 → 解説 → 結果）
struct ContentView: View {
    let chapter: ChapterMetadata
    @ObservedObject var viewModel: QuizViewModel
    let onQuizEnd: () -> Void

    @State private var showExplanation = false
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - 出題／解説の切り替え
            if !viewModel.isLoaded {
                ProgressView("読み込み中…").padding()
            }
            else if viewModel.hasError || viewModel.quizzes.isEmpty {
                VStack(spacing: 12) {
                    Text("問題データが見つかりませんでした。")
                        .foregroundColor(.secondary)
                    Button("単元に戻る") {
                        onQuizEnd()
                    }
                }
                .padding()
            }
            else if viewModel.isFinished {
                ResultView(viewModel: viewModel, onClose: onQuizEnd)
            }
            else {
                QuestionView(
                    question: viewModel.currentQuiz?.question,
                    choices: viewModel.currentQuiz?.choices ?? []
                )

                Divider().padding(.vertical, 8)

                AnswerAreaView(
                    choices: viewModel.currentQuiz?.choices ?? [],
                    selectAction: { selectedIndex in
                        viewModel.recordAnswer(selectedIndex: selectedIndex)
                        showExplanation = true     // ← 解説画面を表示
                    }
                )
            }
        }
        // ✅ NavigationStack 用に modern API を使用
        .navigationDestination(isPresented: $showExplanation) {
            if let quiz = viewModel.currentQuiz {
                ExplanationView(
                    quiz: quiz,
                    selectedAnswerIndex: viewModel.selectedAnswerIndex ?? 0,
                    onNext: {
                        // ✅ moveNext() 後に戻り遷移
                        viewModel.moveNext()
                        showExplanation = false
                    }
                )
            } else {
                Text("解説データを読み込めませんでした。")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
        .navigationTitle("第\(viewModel.currentIndex + 1)問")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !hasLoaded else { return }
            viewModel.chapterId = chapter.id
            viewModel.fetchQuizzes(from: chapter.file)
            hasLoaded = true
        }
    }
}
