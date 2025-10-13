// Views/ContentView.swift
import SwiftUI

/// 出題画面（読み込み → 出題 → 解説 → 結果）
struct ContentView: View {
    let chapter: ChapterMetadata
    @ObservedObject var viewModel: QuizViewModel
    let onQuizEnd: () -> Void

    @State private var goExplanation = false
    @State private var hasLoaded: Bool = false

    var body: some View {
        VStack(spacing: 0) {

            // 隠しリンク（説明画面へ）
            NavigationLink(isActive: $goExplanation) {
                if let quiz = viewModel.currentQuiz, let answer = viewModel.selectedAnswerIndex {
                    ExplanationView(
                        quiz: quiz,
                        selectedAnswerIndex: answer,
                        onNext: {
                            viewModel.moveNext()
                            goExplanation = false
                        }
                    )
                } else {
                    VStack(spacing: 12) {
                        Text("次の問題へ進みます")
                        Button("OK") {
                            viewModel.moveNext()
                            goExplanation = false
                        }
                    }
                    .padding()
                }
            } label: { EmptyView() }.hidden()

            // ローディング
            if !viewModel.isLoaded {
                ProgressView("読み込み中…").padding()
            }
            // エラー/空データ
            else if viewModel.hasError || viewModel.quizzes.isEmpty {
                VStack(spacing: 12) {
                    Text("問題データが見つかりませんでした。")
                        .foregroundColor(.secondary)
                    Button("単元に戻る") {
                        onQuizEnd()   // 親に“閉じる”を委譲
                    }
                }
                .padding()
            }
            // 結果
            else if viewModel.isFinished {
                ResultView(viewModel: viewModel, onClose: onQuizEnd)
            }
            // 出題
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
                        goExplanation = true
                    }
                )
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
