

// Framework/AppFrameView.swift
import SwiftUI

struct AppFrameView: View {
    @StateObject private var router = NavigationRouter()
    @StateObject private var mainViewState = MainViewState()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            MainRouterView()
            Divider()
            BottomTabBarView()
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(router)
        .environmentObject(mainViewState)
    }
}

