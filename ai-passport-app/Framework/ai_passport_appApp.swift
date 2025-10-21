
import SwiftUI
import RealmSwift

/// アプリ起動エントリーポイント
@main
struct ai_passport_appApp: SwiftUI.App {
    init() {
        var configuration = Realm.Configuration(schemaVersion: 1)
        configuration.migrationBlock = { _, _ in }
        Realm.Configuration.defaultConfiguration = configuration

        let repository = RealmAnswerHistoryRepository(configuration: configuration)
        LegacyAnswerHistoryMigrator(repository: repository).migrateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            AppFrameView()
        }
    }
}
