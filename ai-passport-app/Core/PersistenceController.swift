// Core/PersistenceController.swift
import CoreData

final class PersistenceController {

    static let shared = PersistenceController(resetStore: false)

    let container: NSPersistentContainer

    init(resetStore: Bool) {
        container = NSPersistentContainer(name: "ai_passport_app")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        if resetStore {
            destroyStore()
            container.loadPersistentStores { _, error in
                if let error = error {
                    fatalError("Unresolved error after destroy \(error)")
                }
            }
        }
    }

    private func destroyStore() {
        guard let storeDescription = container.persistentStoreDescriptions.first,
              let url = storeDescription.url else { return }

        let coordinator = container.persistentStoreCoordinator
        do {
            if let store = coordinator.persistentStore(for: url) {
                try coordinator.remove(store)
            }
            // ベース、-shm、-wal を安全に削除
            let fileManager = FileManager.default
            let base = url
            let shm  = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let wal  = url.deletingPathExtension().appendingPathExtension("sqlite-wal")

            for target in [base, shm, wal] {
                if fileManager.fileExists(atPath: target.path) {
                    try fileManager.removeItem(at: target)
                }
            }
        } catch {
            print("Failed to destroy Core Data store: \(error)")
        }
    }
}
