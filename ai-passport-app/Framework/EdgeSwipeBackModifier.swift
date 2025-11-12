import SwiftUI

/// View modifier that enables a back navigation gesture from the leading edge
/// of the screen when the header displays a back button.
struct EdgeSwipeBackModifier: ViewModifier {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var router: NavigationRouter

    /// Prevents multiple back actions from firing during a single drag gesture.
    @State private var hasTriggeredSwipe = false

    private let activationEdgeWidth: CGFloat = 24
    private let requiredHorizontalTranslation: CGFloat = 80
    private let maximumVerticalTranslation: CGFloat = 80

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .highPriorityGesture(edgeSwipeGesture)
    }

    private var edgeSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged(handleGestureChange)
            .onEnded { _ in
                hasTriggeredSwipe = false
            }
    }

    private func handleGestureChange(_ value: DragGesture.Value) {
        guard !hasTriggeredSwipe,
              let backButton = mainViewState.headerBackButton,
              value.startLocation.x <= activationEdgeWidth,
              value.translation.width > requiredHorizontalTranslation,
              abs(value.translation.height) < maximumVerticalTranslation else {
            return
        }

        hasTriggeredSwipe = true
        let action = mainViewState.makeBackButtonAction(for: backButton, router: router)
        action()
    }
}

extension View {
    /// Enables the leading-edge swipe gesture that mirrors the header back button.
    func enableEdgeSwipeBackGesture() -> some View {
        modifier(EdgeSwipeBackModifier())
    }
}
