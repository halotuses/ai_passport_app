import SwiftUI

/// 画面共通ヘッダー
struct HeaderView: View {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var router: NavigationRouter

    var body: some View {
        ZStack {
            Text(mainViewState.headerTitle)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                if let backButton = mainViewState.headerBackButton {
                    Button(action: { mainViewState.handleBackAction(backButton, router: router) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text(backButton.title)
                                .font(.body)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .foregroundColor(.black)
                    .buttonStyle(.plain)
                    .accessibilityLabel(backButton.title)
                }

                Spacer()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.3))
        .foregroundColor(.black)
    }
}
