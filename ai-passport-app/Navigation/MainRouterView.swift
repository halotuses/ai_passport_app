// Navigation/MainRouterView.swift
import SwiftUI

struct MainRouterView: View {
    @EnvironmentObject private var router: NavigationRouter

    @StateObject private var unitListVM = UnitListViewModel()
    @StateObject private var chapterListVM = ChapterListViewModel()
    @StateObject private var quizViewModel  = QuizViewModel()   // ← 参照型VMは StateObject

    @State private var selectedUnit: QuizMetadata? = nil
    @State private var selectedChapter: ChapterMetadata? = nil

    var body: some View {
        NavigationStack(path: $router.path) {  // ← router.path をバインド（reset()が効く）
            Group {
                if selectedUnit == nil {
                    // 単元一覧
                    UnitListView(viewModel: unitListVM, selectedUnit: $selectedUnit)
                } else if let unit = selectedUnit, selectedChapter == nil {
                    // 章一覧
                    ChapterListView(unit: unit, viewModel: chapterListVM, selectedChapter: $selectedChapter)
                } else if let chapter = selectedChapter {
                    // 出題
                    ContentView(chapter: chapter, viewModel: quizViewModel) {
                        // クイズ終了時の戻し処理
                        quizViewModel.reset()
                        selectedChapter = nil
                        selectedUnit = nil
                        router.reset() // NavigationStackの履歴も全クリア
                    }
                }
            }
            .animation(.default, value: selectedUnit == nil)
            .animation(.default, value: selectedChapter == nil)
        }
    }
}
