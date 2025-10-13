import SwiftUI

/// NavigationStack 統括管理
class NavigationRouter: ObservableObject {
    
    @Published var path = NavigationPath()
    
    /// トップに戻す処理
    func reset() {
        path = NavigationPath()
    }
}
