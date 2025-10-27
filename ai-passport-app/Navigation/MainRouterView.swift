
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
                
                ContentStateView(
                    unitListViewModel: unitListVM,
                    selectedUnit: selectedUnitBinding,
                    selectedChapter: selectedChapterBinding,
                    onQuizEnd: { mainViewState.reset(router: router) },
                    onBackToChapterSelection: { mainViewState.backToChapterSelection(router: router) },
                    onBackToUnitSelection: { mainViewState.backToUnitSelection(router: router) }
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

private extension MainRouterView {
    var selectedUnitBinding: Binding<QuizMetadata?> {
        Binding(
            get: { mainViewState.selectedUnit },
            set: { mainViewState.selectedUnit = $0 }
        )
    }

    var selectedChapterBinding: Binding<ChapterMetadata?> {
        Binding(
            get: { mainViewState.selectedChapter },
            set: { mainViewState.selectedChapter = $0 }
        )
    }
}
