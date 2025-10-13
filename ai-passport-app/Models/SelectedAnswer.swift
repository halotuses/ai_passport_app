import Foundation

/// モデル: 選択された回答インデックス (現状は未使用・今後の進捗保存用)
struct SelectedAnswer: Identifiable {
    let id = UUID()
    let index: Int
}
