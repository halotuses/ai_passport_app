

import AudioToolbox
import Foundation

/// シンプルな効果音管理クラス。
/// AudioToolbox を使用して低レイテンシでサウンドを再生する。
final class SoundManager {
    static let shared = SoundManager()

    enum SoundType: String, CaseIterable {
        case correct
        case wrong
        case tap

        fileprivate var fileName: String { rawValue }
        fileprivate var fileExtension: String { "wav" }
    }

    private var soundIDs: [SoundType: SystemSoundID] = [:]
    private let accessQueue = DispatchQueue(label: "com.ai-passport.soundManager")

    private init() {}

    deinit {
        accessQueue.sync {
            soundIDs.values.forEach { soundID in
                AudioServicesDisposeSystemSoundID(soundID)
            }
            soundIDs.removeAll()
        }
    }

    func play(_ type: SoundType) {
        guard let soundID = prepareSoundID(for: type) else { return }
        AudioServicesPlaySystemSound(soundID)
    }

    private func prepareSoundID(for type: SoundType) -> SystemSoundID? {
        if let cachedID = accessQueue.sync(execute: { soundIDs[type] }) {
            return cachedID
        }

        guard let url = Bundle.main.url(forResource: type.fileName, withExtension: type.fileExtension) else {
            return nil
        }

        var newSoundID: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &newSoundID)

        guard status == kAudioServicesNoError else {
            return nil
        }

        return accessQueue.sync {
            if let existing = soundIDs[type] {
                AudioServicesDisposeSystemSoundID(newSoundID)
                return existing
            }
            soundIDs[type] = newSoundID
            return newSoundID
        }
    }
}
