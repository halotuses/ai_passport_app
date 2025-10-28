import Foundation
import RealmSwift

/// Realmの初期化・生成処理を集中管理するマネージャ
/// - ディレクトリの生成やファイル破損時の再生成を担う
/// - 同期キューで初期化処理の並列実行を防ぐ
final class RealmManager {
    static let shared = RealmManager()

    private let fileManager: FileManager
    private let accessQueue = DispatchQueue(label: "ai-passport-app.realm.manager")

    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// アプリ共通のデフォルトRealm設定を適用し、必要であればディレクトリを生成する
    func configureDefaultRealmIfNeeded(_ configuration: Realm.Configuration) {
        accessQueue.sync {
            do {
                try prepareDirectoryIfNeeded(for: configuration)
                Realm.Configuration.defaultConfiguration = configuration
                logStatus(prefix: "✅", message: "Default Realm configured", configuration: configuration)
            } catch {
                logStatus(prefix: "❌", message: "Failed to configure default Realm: \(error)", configuration: configuration)
            }
        }
    }

    /// 指定した設定でRealmを生成する。ディレクトリ未生成やファイル破損時には再生成を試みる
    func realm(configuration: Realm.Configuration = Realm.Configuration.defaultConfiguration) throws -> Realm {
        try accessQueue.sync {
            try prepareDirectoryIfNeeded(for: configuration)

            do {
                let realm = try Realm(configuration: configuration)
                logStatus(prefix: "✅", message: "Realm initialized", configuration: configuration)
                return realm
            } catch {
                logStatus(prefix: "⚠️", message: "Realm initialization failed: \(error). Attempting recovery.", configuration: configuration)
                try recoverRealmFileIfNeeded(for: configuration)
                let realm = try Realm(configuration: configuration)
                logStatus(prefix: "✅", message: "Realm reinitialized after recovery", configuration: configuration)
                return realm
            }
        }
    }

    private func prepareDirectoryIfNeeded(for configuration: Realm.Configuration) throws {
        guard let fileURL = configuration.fileURL else { return }
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            logStatus(prefix: "✅", message: "Created Realm directory", configuration: configuration)
        }
    }

    private func recoverRealmFileIfNeeded(for configuration: Realm.Configuration) throws {
        guard let fileURL = configuration.fileURL else { return }
        try prepareDirectoryIfNeeded(for: configuration)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            logStatus(prefix: "⚠️", message: "Removed corrupted Realm file", configuration: configuration)
        }
    }

    private func logStatus(prefix: String, message: String, configuration: Realm.Configuration) {
        if let path = configuration.fileURL?.path {
            print("\(prefix) \(message): \(path)")
        } else {
            print("\(prefix) \(message)")
        }
    }
}
