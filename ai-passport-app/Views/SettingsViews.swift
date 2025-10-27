import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var progressManager: ProgressManager
    @EnvironmentObject private var mainViewState: MainViewState
    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(AppSettingsKeys.fontSizeIndex) private var fontSizeIndex = AppFontSettings.defaultIndex

    @State private var showResetConfirmation = false
    @State private var showInitializationConfirmation = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var previousHeaderState: (title: String, backButton: MainViewState.HeaderBackButton?)?

    private let fontSliderRange = 0.0...Double(AppFontSettings.options.count - 1)

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                accountSection
                dataSection
                supportSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(Color.themeBase.ignoresSafeArea())
        .navigationTitle("設定")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("閉じる") { dismiss() }
                    .foregroundColor(.themeAccent)
            }
        }
        .alert("データリセット", isPresented: $showResetConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive, action: performDataReset)
        } message: {
            Text("学習履歴をリセットします。よろしいですか？")
        }
        .alert("アプリを初期化", isPresented: $showInitializationConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("初期化", role: .destructive, action: performInitialization)
        } message: {
            Text("全ての学習データと設定を削除します。よろしいですか？")
        }
        .alert("エラー", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .onAppear {
            previousHeaderState = (mainViewState.headerTitle, mainViewState.headerBackButton)
            mainViewState.setHeader(title: "設定")
        }
        .onDisappear {
            if let previousHeaderState {
                mainViewState.setHeader(title: previousHeaderState.title, backButton: previousHeaderState.backButton)
            }
        }
    }
}

private extension SettingsView {
    var accountSection: some View {
        SettingsSection(title: "アカウント設定") {
            NavigationLink {
                AccountView()
            } label: {
                SettingsRow {
                    rowLabel(title: "アカウント", systemImage: "person.crop.circle", tint: .themeAccent)
                }
            }
            .buttonStyle(.plain)

            SettingsRow {
                Toggle(isOn: $soundEnabled) {
                    Label("サウンド", systemImage: "speaker.wave.2.fill")
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.themeMain))
            }

            SettingsRow(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    Label("フォントサイズ", systemImage: "textformat.size")
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            Slider(
                                value: Binding(
                                    get: { Double(fontSizeIndex) },
                                    set: { fontSizeIndex = Int($0.rounded()) }
                                ),
                                in: fontSliderRange,
                                step: 1
                            )
                            .tint(.themeMain)

                            Text("現在：\(currentFontOption.label)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.themeTextPrimary)
                        }

                        HStack {
                            Text("小")
                            Spacer()
                            Text("大")
                        }
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
    }

    var dataSection: some View {
        SettingsSection(title: "データ管理") {
            SettingsRow {
                Button {
                    showResetConfirmation = true
                } label: {
                    rowLabel(title: "データリセット", systemImage: "arrow.counterclockwise", tint: .red, titleColor: .red, showsChevron: false)
                }
                .buttonStyle(.plain)
            }

            SettingsRow {
                Button {
                    showInitializationConfirmation = true
                } label: {
                    rowLabel(title: "初期化", systemImage: "trash.fill", tint: .red, titleColor: .red, showsChevron: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var supportSection: some View {
        SettingsSection(title: "サポート・情報") {
            SettingsRow {
                Button {
                    openSupport()
                } label: {
                    rowLabel(title: "お問い合わせ", systemImage: "envelope.fill", tint: .themeAccent)
                }
                .buttonStyle(.plain)
            }

            SettingsRow {
                NavigationLink {
                    TermsView()
                } label: {
                    rowLabel(title: "利用規約", systemImage: "doc.text", tint: .themeAccent)
                }
                .buttonStyle(.plain)
            }

            SettingsRow {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    rowLabel(title: "プライバシーポリシー", systemImage: "lock.shield", tint: .themeAccent)
                }
                .buttonStyle(.plain)
            }

            SettingsRow(alignment: .leading) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("バージョン情報", systemImage: "info.circle")
                    Text("バージョン \(appVersion)")
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                }
            }
        }
    }

    var currentFontOption: AppFontSizeOption {
        AppFontSettings.option(for: fontSizeIndex)
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "\(version) (\(build))"
    }

    func rowLabel(title: String, systemImage: String, tint: Color, titleColor: Color = .themeTextPrimary, showsChevron: Bool = true) -> some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .foregroundColor(tint)
            Text(title)
                .foregroundColor(titleColor)
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.themeTextSecondary)
            }
        }
        .contentShape(Rectangle())
    }

    func openSupport() {
        if let url = URL(string: "mailto:support@ai-passport.jp") {
            open(link: url)
        }
    }

    func open(link: URL) {
        openURL(link)
    }

    func performDataReset() {
        do {
            try progressManager.repository.deleteAllProgress()
            progressManager.homeProgressViewModel.refresh()
        } catch {
            presentError(message: "データのリセットに失敗しました。\n\(error.localizedDescription)")
        }
    }

    func performInitialization() {
        do {
            try progressManager.repository.deleteAllData()
            resetSettings()
            progressManager.homeProgressViewModel.refresh()
        } catch {
            presentError(message: "初期化に失敗しました。\n\(error.localizedDescription)")
        }
    }

    func resetSettings() {
        soundEnabled = true
        fontSizeIndex = AppFontSettings.defaultIndex
    }

    func presentError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            VStack(spacing: 12) {
                content
            }
        }
    }
}

private struct SettingsRow<Content: View>: View {
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 12
    @ViewBuilder let content: Content

    init(alignment: HorizontalAlignment = .center, spacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeSurface)
                .shadow(color: Color.themeShadowSoft.opacity(0.4), radius: 10, x: 0, y: 6)
        )
    }
}
