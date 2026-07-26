import SwiftUI

extension Color {
    // Apple のプロダクトページのように、ニュートラルな面と 1 つの青を基調にする。
    static let themeBase = Color(red: 245/255, green: 245/255, blue: 247/255)
    static let themeMain = Color(red: 10/255, green: 132/255, blue: 255/255)
    static let themeMainHover = Color(red: 0/255, green: 113/255, blue: 227/255)
    static let themeAccent = Color(red: 0/255, green: 113/255, blue: 227/255)
    static let themeSecondary = Color(red: 0/255, green: 113/255, blue: 227/255)
    // ナビゲーション領域だけに使う、彩度を抑えたブランドグラデーション。
    static let themeNavigationStart = Color(red: 61/255, green: 193/255, blue: 198/255)
    static let themeNavigationEnd = Color(red: 82/255, green: 123/255, blue: 229/255)
    static let themeTertiary = Color(red: 255/255, green: 186/255, blue: 92/255)
    static let themeQuaternary = Color(red: 241/255, green: 121/255, blue: 171/255)
    static let themeSurface = Color.white

    static let themeSurfaceElevated = Color.white
    static let themeSurfaceAlt = Color(red: 250/255, green: 250/255, blue: 252/255)
    static let themePillBackground = Color(red: 229/255, green: 242/255, blue: 255/255)
    static let themeBadgeBackground = Color(red: 232/255, green: 240/255, blue: 254/255)
    static let themeTextPrimary = Color(red: 29/255, green: 29/255, blue: 31/255)
    static let themeTextSecondary = Color(red: 110/255, green: 110/255, blue: 115/255)
    static let themeButtonSecondary = Color(red: 229/255, green: 242/255, blue: 255/255)
    static let themeButtonSecondaryHover = Color(red: 207/255, green: 232/255, blue: 255/255)
    static let themeShadowSoft = Color.black.opacity(0.055)
    static let themeCorrect = Color(red: 48/255, green: 176/255, blue: 80/255)
    static let themeIncorrect = Color(red: 226/255, green: 72/255, blue: 86/255)

    static let crownGoldLight = Color(red: 0.93, green: 0.80, blue: 0.40)
    static let crownGoldDeep = Color(red: 0.80, green: 0.65, blue: 0.20)
    static let crownGoldHighlight = Color(red: 1.00, green: 0.90, blue: 0.60)
    
    static let themeAnswerGradientStart = Color(red: 255/255, green: 220/255, blue: 80/255)
    static let themeAnswerGradientEnd = Color(red: 255/255, green: 150/255, blue: 80/255)

}

extension Gradient {
    static let crownGold = Gradient(colors: [.crownGoldLight, .crownGoldDeep, .crownGoldHighlight])
}

extension LinearGradient {
    static let crownGold = LinearGradient(gradient: .crownGold, startPoint: .topLeading, endPoint: .bottomTrailing)
}
