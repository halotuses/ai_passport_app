import SwiftUI
import Foundation
import RealmSwift

/// アプリ起動エントリーポイント
@main
struct ai_passport_appApp: SwiftUI.App {
    @StateObject private var progressManager: ProgressManager
    init() {
        // Realm設定
        var configuration = Realm.Configuration(schemaVersion: 3)
        configuration.deleteRealmIfMigrationNeeded = true
        do {
            let fileManager = FileManager.default
            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let realmDirectory = appSupportURL.appendingPathComponent("Realm", isDirectory: true)
            try fileManager.createDirectory(at: realmDirectory, withIntermediateDirectories: true)
            configuration.fileURL = realmDirectory.appendingPathComponent("answer-history.realm")
        } catch {
            print("❌ Failed to prepare Realm directory: \(error)")
        }
        RealmManager.shared.configureDefaultRealmIfNeeded(configuration)
        // Realmファイルのパスを出力
        if let url = Realm.Configuration.defaultConfiguration.fileURL {
            print("✅ Realm file path:")
            print(url)
        }

        // Realmリポジトリの準備とマイグレーションなどの初期化処理
        let repository = RealmAnswerHistoryRepository(configuration: configuration)
        LegacyAnswerHistoryMigrator(repository: repository).migrateIfNeeded()
        _progressManager = StateObject(wrappedValue: ProgressManager(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootContainerView()
                .environmentObject(progressManager)
        }
    }
}
