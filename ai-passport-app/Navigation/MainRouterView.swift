
// Navigation/MainRouterView.swift
import SwiftUI

struct MainRouterView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var progressManager: ProgressManager
    @StateObject private var unitListVM = UnitListViewModel()

    
    var body: some View {
        NavigationStack(path: $router.path) {  // ← router.path をバインド（reset()が効く）
            ZStack {
                Color.themeBase
                    .ignoresSafeArea()
                
                Group {
                    if mainViewState.isOnHome {

                        HomeView(viewModel: progressManager.homeViewModel)
                    } else if mainViewState.selectedUnit == nil {
                        // 単元一覧
                        UnitListView(viewModel: unitListVM, selectedUnit: $mainViewState.selectedUnit)
                    } else if let unit = mainViewState.selectedUnit,
                              mainViewState.selectedChapter == nil {
                        // 章一覧
                        ChapterListView(
                            unitKey: mainViewState.selectedUnitKey ?? "unknown",
                            unit: unit,
                            viewModel: progressManager.chapterListViewModel,
                            selectedChapter: $mainViewState.selectedChapter
                        )
                    } else if let chapter = mainViewState.selectedChapter {
                        // 出題
                        ContentView(
                            chapter: chapter,
                            viewModel: progressManager.quizViewModel,
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
