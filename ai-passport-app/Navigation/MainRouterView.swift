
// Navigation/MainRouterView.swift
import SwiftUI

struct MainRouterView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var mainViewState: MainViewState
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var unitListVM = UnitListViewModel()
    @StateObject private var chapterListVM = ChapterListViewModel()
    @StateObject private var quizViewModel  = QuizViewModel()   // ← 参照型VMは StateObject
    
    var body: some View {
        NavigationStack(path: $router.path) {  // ← router.path をバインド（reset()が効く）
            ZStack {
                Color.themeBase
                    .ignoresSafeArea()
                
                Group {
                    if mainViewState.isOnHome {
                        HomeView(viewModel: homeViewModel)
                    } else if mainViewState.selectedUnit == nil {
                        // 単元一覧
                        UnitListView(viewModel: unitListVM, selectedUnit: $mainViewState.selectedUnit)
                    } else if let unit = mainViewState.selectedUnit,
                              mainViewState.selectedChapter == nil {
                        // 章一覧
                        ChapterListView(
                            unitKey: mainViewState.selectedUnitKey ?? "unknown",
                            unit: unit,
                            viewModel: chapterListVM,
                            selectedChapter: $mainViewState.selectedChapter
                        )
                    } else if let chapter = mainViewState.selectedChapter {
                        // 出題
                        ContentView(
                            chapter: chapter,
                            viewModel: quizViewModel,
                            onQuizEnd: {
                                mainViewState.reset(router: router)
                            },
                            onBackToChapterSelection: {
                                mainViewState.backToChapterSelection(router: router)
                            },
                            onBackToUnitSelection: {
                                mainViewState.backToUnitSelection(router: router)
                            }
                        )
                    }
                }
            }
        }
    }
}
