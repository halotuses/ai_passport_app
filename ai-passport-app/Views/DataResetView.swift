import SwiftUI

struct DataResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressManager: ProgressManager

    @State private var showResetConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                infoCard

                actionSection
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(subtlePaperBackground.ignoresSafeArea())
        .navigationTitle("データリセット")
        .navigationBarTitleDisplayMode(.inline)
        .alert("データリセット", isPresented: $showResetConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("リセット", role: .destructive) { performDataReset() }
        } message: {
            Text("学習履歴をリセットします。よろしいですか？")
        }
        .alert("エラー", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    private func performDataReset() {
        guard !isProcessing else { return }
        isProcessing = true

        do {
            try progressManager.repository.deleteAllProgress()
            progressManager.homeProgressViewModel.refresh()
            isProcessing = false
            dismiss()
        } catch {
            errorMessage = "データのリセットに失敗しました。\n\(error.localizedDescription)"
            isProcessing = false
            showErrorAlert = true
        }
    }
    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.themeIncorrect, Color.themeSecondary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("学習履歴のリセット")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)

                    Text("すべての回答履歴や進捗状況が削除されます。ブックマークやアカウント情報は保持されますが、元に戻すことはできません。")
                        .font(.body)
                        .foregroundColor(.themeTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.25))

            VStack(alignment: .leading, spacing: 12) {
                Label {
                    Text("必要に応じてリセットを実行してください。")
                        .foregroundColor(.themeTextPrimary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.themeSecondary)
                }

                Label {
                    Text("リセット後はこの操作を取り消すことができません。")
                        .foregroundColor(.themeTextPrimary)
                } icon: {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.themeTextSecondary)
                }
            }
            .font(.subheadline)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.4), radius: 18, x: 0, y: 12)
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button(action: { showResetConfirmation = true }) {
                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.95))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("学習履歴をリセット")
                            .font(.headline)
                        Text("回答履歴と進捗状況を削除します")
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .opacity(0.8)
                    }
                }
                .foregroundColor(.white)
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.themeIncorrect,
                                    Color.themeIncorrect.opacity(0.85),
                                    Color.themeIncorrect.opacity(0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: Color.themeIncorrect.opacity(0.28), radius: 16, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.75 : 1.0)

            VStack(alignment: .leading, spacing: 8) {
                Text("※ この操作は取り消せません")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.themeIncorrect)

                Text("リセット後は、学習履歴の復元はできません。実行する前に内容を十分に確認してください。")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtlePaperBackground: some View {
        LinearGradient(
            colors: [
                Color.themeBase,
                Color.themeBase.opacity(0.98),
                Color.themeSurfaceElevated.opacity(0.96)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            Color.white
                .opacity(0.04)
        )
    }
}

#Preview {
    NavigationStack {
        DataResetView()
            .environmentObject(ProgressManager())
    }
}
