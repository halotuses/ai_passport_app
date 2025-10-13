import SwiftUI

/// 下部タブバー（ダミー）
struct BottomTabBarView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Image(systemName: "house.fill")
                Text("ホーム").font(.caption)
            }
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
