

// Framework/AppFrameView.swift
import SwiftUI

struct AppFrameView: View {
    @StateObject private var router = NavigationRouter()
    @StateObject private var mainViewState = MainViewState()
    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(AppSettingsKeys.fontSizeIndex) private var fontSizeIndex = AppFontSettings.defaultIndex
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
            Divider()
            MainRouterView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            BottomTabBarView(onTapSettings: {
                isShowingSettings = true
            })
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(router)
        .environmentObject(mainViewState)
        .environment(\.appSoundEnabled, soundEnabled)
        .environment(\.dynamicTypeSize, AppFontSettings.option(for: fontSizeIndex).dynamicTypeSize)
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView()
            }
            .environment(\.appSoundEnabled, soundEnabled)
            .environment(\.dynamicTypeSize, AppFontSettings.option(for: fontSizeIndex).dynamicTypeSize)
        }
    }
}

