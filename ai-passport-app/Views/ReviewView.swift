import SwiftUI

/// 復習機能のメイン画面
struct ReviewView: View {
    @EnvironmentObject private var mainViewState: MainViewState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerSection
                contentPlaceholder
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
        )
        .onAppear {
            mainViewState.setHeader(title: "復習", backButton: .toHome)
        }
    }
}

private extension ReviewView {
    var headerSection: some View {
        VStack(spacing: 8) {
            Text("復習を始めましょう")
                .font(.title2.weight(.semibold))
                .foregroundColor(.themeTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("間違えた問題や後で見返したい内容をここでまとめて学習できます。")
                .font(.subheadline)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    var contentPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.themeSecondary)

            Text("復習機能は近日公開予定です。")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)

            Text("学習した問題の振り返り機能を準備しています。アップデートをお待ちください。")
                .font(.footnote)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.themeSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 18, x: 0, y: 12)
    }
}

#Preview {
    ReviewView()
        .environmentObject(MainViewState())
}
