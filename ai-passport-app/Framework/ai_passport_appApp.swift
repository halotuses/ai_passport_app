import SwiftUI
import Foundation
import RealmSwift

/// アプリ起動エントリーポイント
@main
struct ai_passport_appApp: SwiftUI.App {
    init() {
        // Realm設定
        var configuration = Realm.Configuration(schemaVersion: 2)
        configuration.deleteRealmIfMigrationNeeded = true
        let fileManager = FileManager.default
        do {
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
        Realm.Configuration.defaultConfiguration = configuration

        // Realmファイルのパスを出力
        if let url = Realm.Configuration.defaultConfiguration.fileURL {
            print("✅ Realm file path:")
            print(url)
        }

        // マイグレーションなどの初期化処理
        let repository = RealmAnswerHistoryRepository(configuration: configuration)
        LegacyAnswerHistoryMigrator(repository: repository).migrateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppFrameView()
        }
    }
}
