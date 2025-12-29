import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled = true
    @AppStorage(AppSettingsKeys.fontSizeIndex) private var fontSizeIndex = AppFontSettings.defaultIndex
    @AppStorage(AppSettingsKeys.bookmarkShowCorrectAnswers) private var bookmarkShowCorrectAnswers = true


    private let fontSliderRange = 0.0...Double(AppFontSettings.options.count - 1)

    var body: some View {
        ZStack {
            Color.themeBase
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleSection

                ScrollView {
                    VStack(spacing: 28) {
                        accountSection
                        bookmarkSection
                        dataSection
                        supportSection
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal, -20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        
    }
}

private extension SettingsView {
    var titleSection: some View {
        ZStack {
            HStack {
                Spacer()
                closeButton
            }
            Text("設定")
                .font(.title2.bold())
                .foregroundColor(.themeTextPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.themeBase)
    }


    var closeButton: some View {
        Button("閉じる") {
            dismiss()
        }
        .font(.body)
        .foregroundColor(.themeTextPrimary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.themeTextSecondary.opacity(0.12))
        )
    }
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

                            Text("\(currentFontOption.label)")
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

    var bookmarkSection: some View {
        SettingsSection(title: "ブックマーク") {
            SettingsRow {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("正解の表示")
                            .font(.headline)
                            .foregroundColor(.themeTextPrimary)
                        Text("ブックマークした問題の正解について表示・非表示を設定できます。")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                    Spacer()
                    Toggle("", isOn: $bookmarkShowCorrectAnswers)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color.themeMain))
                }
            }
        }
    }
    
    var dataSection: some View {
        SettingsSection(title: "データ管理") {
            SettingsRow {
                NavigationLink {
                    DataResetView()
                } label: {
                    rowLabel(title: "データリセット", systemImage: "arrow.counterclockwise", tint: .red, titleColor: .red)
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
        if let url = URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSc8-n5BuZjd_uG1co2_oMmwc-lQaw5GznifL7Z6XFO209MmAw/viewform") {
            open(link: url)
        }
    }

    func open(link: URL) {
        openURL(link)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    private let content: Content

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
    private let content: Content

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
