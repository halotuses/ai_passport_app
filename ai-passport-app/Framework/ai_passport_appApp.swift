import SwiftUI
import RealmSwift

/// アプリ起動エントリーポイント
@main
struct ai_passport_appApp: SwiftUI.App {
    init() {
        // Realm設定
        var configuration = Realm.Configuration(schemaVersion: 2)
        configuration.deleteRealmIfMigrationNeeded = true
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
