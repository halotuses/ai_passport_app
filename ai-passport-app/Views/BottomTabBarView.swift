 import SwiftUI
 
 /// 下部タブバー（ダミー）
 struct BottomTabBarView: View {
    @EnvironmentObject private var router: NavigationRouter
    @EnvironmentObject private var mainViewState: MainViewState

     var body: some View {
         HStack {
             Spacer()
            Button(action: { mainViewState.reset(router: router) }) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("ホーム").font(.caption)
                }
             }
            .buttonStyle(.plain)
             Spacer()
             VStack {
                 Image(systemName: "person.fill")
                 Text("アカウント").font(.caption)
             }
             Spacer()
             VStack {
                 Image(systemName: "gearshape.fill")
                 Text("設定").font(.caption)
             }
             Spacer()
         }
         .padding()
         .background(Color.gray.opacity(0.2))
     }
 }
