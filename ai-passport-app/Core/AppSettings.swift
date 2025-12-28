import SwiftUI

enum AppSettingsKeys {
    static let soundEnabled = "settings.soundEnabled"
    static let fontSizeIndex = "settings.fontSizeIndex"
    static let bookmarkShowCorrectAnswers = "settings.bookmark.showCorrectAnswers"
}

struct AppFontSizeOption: Identifiable {
    let id: Int
    let label: String
    let dynamicTypeSize: DynamicTypeSize
}

enum AppFontSettings {
    static let options: [AppFontSizeOption] = [
        AppFontSizeOption(id: 0, label: "極小", dynamicTypeSize: .xSmall),
        AppFontSizeOption(id: 1, label: "小", dynamicTypeSize: .small),
        AppFontSizeOption(id: 2, label: "標準", dynamicTypeSize: .medium),
        AppFontSizeOption(id: 3, label: "大", dynamicTypeSize: .large),
        AppFontSizeOption(id: 4, label: "特大", dynamicTypeSize: .xLarge),
        AppFontSizeOption(id: 5, label: "最大", dynamicTypeSize: .xxLarge),
        AppFontSizeOption(id: 6, label: "超特大", dynamicTypeSize: .xxxLarge)
    ]

    static let defaultIndex: Int = 3

    static func option(for index: Int) -> AppFontSizeOption {
        options.first(where: { $0.id == index }) ?? options[defaultIndex]
    }
}
enum AppSoundSettings {
    private static let defaults: UserDefaults = .standard

    static var isEnabled: Bool {
        guard defaults.object(forKey: AppSettingsKeys.soundEnabled) != nil else { return true }
        return defaults.bool(forKey: AppSettingsKeys.soundEnabled)
    }
}
private struct AppSoundEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = AppSoundSettings.isEnabled
}

extension EnvironmentValues {
    var appSoundEnabled: Bool {
        get { self[AppSoundEnabledKey.self] }
        set { self[AppSoundEnabledKey.self] = newValue }
    }
}
