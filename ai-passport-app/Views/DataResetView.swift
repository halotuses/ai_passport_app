import SwiftUI

struct DataResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressManager: ProgressManager

    @State private var showResetConfirmation = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("学習履歴をリセットすると、すべての回答履歴や進捗状況が削除されます。")
                    Text("ブックマークやアカウント情報は保持されますが、リセット後に元に戻すことはできません。")
                    Text("内容を確認し、必要であればリセットを実行してください。")
                }
                .font(.body)
                .foregroundColor(.themeTextPrimary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.themeSurface)
                        .shadow(color: Color.themeShadowSoft.opacity(0.4), radius: 10, x: 0, y: 6)
                )
            }

            VStack(spacing: 12) {
                Button(action: { showResetConfirmation = true }) {
                    Text(isProcessing ? "リセット中..." : "学習履歴をリセット")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.themeIncorrect)
                        )
                }
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.6 : 1.0)

                Text("※ この操作は取り消せません。")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(Color.themeBase.ignoresSafeArea())
        .navigationTitle("データリセット")
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
}

#Preview {
    DataResetView()
}
