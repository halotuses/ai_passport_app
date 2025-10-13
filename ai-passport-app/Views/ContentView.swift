//
//  ContentView.swift
//  ai-passport-app
//

import SwiftUI

struct ContentView: View {
    let chapter: ChapterMetadata
    @ObservedObject var viewModel: QuizViewModel
    let onQuizEnd: () -> Void
    
    @EnvironmentObject private var mainViewState: MainViewState
    
    @State private var goExplanation = false
    @State private var hasLoaded = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - ExplanationView 遷移リンク
            NavigationLink(isActive: $goExplanation) {
                if let quiz = viewModel.currentQuiz {
                    ExplanationView(
                        quiz: quiz,
                        selectedAnswerIndex: viewModel.selectedAnswerIndex ?? 0,
                        hasNextQuestion: viewModel.hasNextQuestion,
                        
                        onNextQuestion: {
                            viewModel.moveNext()
                        },
                        onDismiss: {
                            withAnimation {
                                goExplanation = false
                            }
                            
                        }
                    )
                } else {
                    EmptyView()
                }
            } label: {
                EmptyView()
            }
            .hidden()
            
            // MARK: - ロード状態
            if !viewModel.isLoaded {
                ProgressView("読み込み中...")
                    .padding()
            }
            
            
            
            // MARK: - エラーまたはデータ無し
            else if viewModel.hasError || viewModel.quizzes.isEmpty {
                VStack(spacing: 12) {
                    Text("問題データが見つかりませんでした。")
                        .foregroundColor(.secondary)
                    
                    Button("前に戻る") {
                        onQuizEnd()
                    }
                }
                .padding()
            }
            
            // MARK: - クイズ完了
            else if viewModel.isFinished {
                ResultView(
                    correctCount: viewModel.correctCount,
                    totalCount: viewModel.totalCount,
                    onRestart: onQuizEnd
                )
            }
            
            // MARK: - 問題画面
            else {
                
                VStack(spacing: 0) {
                    QuestionView(viewModel: viewModel)
                        .padding(.top, 12)
                    
                    
                    Spacer(minLength: 0)
                    
                    
                    Divider()
                        .padding(.top, 12)
                    
                    AnswerAreaView(
                        choices: viewModel.currentQuiz?.choices ?? [],
                        selectAction: { selectedIndex in
                            viewModel.recordAnswer(selectedIndex: selectedIndex)
                            goExplanation = true
                        }
                    )
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        .onAppear {
            guard !hasLoaded else { return }
            loadQuizzes()
            hasLoaded = true
        }
        .onChange(of: chapter.id) { _ in
            loadQuizzes()
        }
        
        
        .onChange(of: mainViewState.navigationResetToken) { _ in
            goExplanation = false
            viewModel.reset()
        }
        
    }
}

private extension ContentView {
    func loadQuizzes() {
        let chapterFilePath = chapter.file
        viewModel.unitId = extractUnitIdentifier(from: chapterFilePath)
        viewModel.chapterId = chapter.id
        viewModel.fetchQuizzes(from: chapterFilePath)
    }
    
    func extractUnitIdentifier(from path: String) -> String {
        let components = path.split(separator: "/")
        if let unitComponent = components.first(where: { $0.hasPrefix("unit") }) {
            return String(unitComponent)
        }
        return ""
    }
}
