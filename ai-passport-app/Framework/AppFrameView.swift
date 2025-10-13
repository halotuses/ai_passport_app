// Framework/AppFrameView.swift
import SwiftUI

struct AppFrameView: View {
    @StateObject private var router = NavigationRouter()

    // 開発中のみ初期化したい場合は App 側で制御し、ここは shared を使う
    private let persistenceController = PersistenceController.shared

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "学習アプリ")
            Divider()
            MainRouterView()
            Divider()
            BottomTabBarView()
        }
        .edgesIgnoringSafeArea(.bottom)
        .environmentObject(router)
        .environment(\.managedObjectContext, persistenceController.container.viewContext)
    }
}
