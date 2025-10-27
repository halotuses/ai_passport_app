import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// アプリ起動時に一度だけ表示されるスプラッシュ画面。
struct SplashView: View {
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "Version \(version) \(build)"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(.systemBackground)
                .ignoresSafeArea()

            Text(versionText)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.top, 16)
                .padding(.trailing, 20)

            VStack(spacing: 24) {
                Spacer()

                SplashLogoGraphic()
                    .frame(width: 160, height: 160)

                VStack(spacing: 8) {
                    Text("Now loading")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                }

                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

private struct SplashLogoGraphic: View {
    var body: some View {
        Group {
#if canImport(UIKit)
            if let image = UIImage(named: "SplashLogo") ?? UIImage(named: "dokugaku_today_logo") ?? UIImage(named: "AppIcon") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                fallback
            }
#elseif canImport(AppKit)
            if let image = NSImage(named: "SplashLogo") ?? NSImage(named: "dokugaku_today_logo") ?? NSImage(named: "AppIcon") {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                fallback
            }
#else
            fallback
#endif
        }
    }

    private var fallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.accentColor.opacity(0.15))
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .padding(36)
                .foregroundColor(.accentColor)
        }
    }
}

#Preview {
    SplashView()
}
