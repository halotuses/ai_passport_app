import SwiftUI

/// 画面共通ヘッダー
struct HeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.3))
            .foregroundColor(.black)
    }
}
