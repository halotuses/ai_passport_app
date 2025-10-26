import SwiftUI

extension Color {
    static let themeBase = Color(red: 249/255, green: 252/255, blue: 251/255)
    static let themeMain = Color(red: 64/255, green: 224/255, blue: 208/255)
    static let themeMainHover = Color(red: 26/255, green: 168/255, blue: 156/255)
    static let themeAccent = Color(red: 26/255, green: 168/255, blue: 156/255)
    static let themeSecondary = Color(red: 94/255, green: 129/255, blue: 255/255)
    static let themeTertiary = Color(red: 255/255, green: 186/255, blue: 92/255)
    static let themeQuaternary = Color(red: 241/255, green: 121/255, blue: 171/255)
    static let themeSurface = Color.white

    static let themeSurfaceElevated = Color(red: 244/255, green: 251/255, blue: 249/255)
    static let themeSurfaceAlt = Color(red: 248/255, green: 248/255, blue: 255/255)
    static let themePillBackground = Color(red: 216/255, green: 235/255, blue: 231/255)
    static let themeBadgeBackground = Color(red: 224/255, green: 231/255, blue: 250/255)
    static let themeTextPrimary = Color(red: 47/255, green: 47/255, blue: 47/255)
    static let themeTextSecondary = Color(red: 94/255, green: 104/255, blue: 104/255)
    static let themeButtonSecondary = Color(red: 200/255, green: 232/255, blue: 224/255)
    static let themeButtonSecondaryHover = Color(red: 167/255, green: 239/255, blue: 231/255)
    static let themeShadowSoft = Color.black.opacity(0.08)
    static let themeCorrect = Color(red: 119/255, green: 221/255, blue: 119/255)
    static let themeIncorrect = Color(red: 246/255, green: 114/255, blue: 128/255)
    
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

