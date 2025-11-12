import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// View modifier that enables a back navigation gesture from the leading edge
/// of the screen when the header displays a back button.
struct EdgeSwipeBackModifier: ViewModifier {
    @EnvironmentObject private var mainViewState: MainViewState
    @EnvironmentObject private var router: NavigationRouter

    /// Prevents multiple back actions from firing during a single drag gesture.
    @State private var hasTriggeredSwipe = false
    @State private var hasPreparedFeedback = false
#if canImport(UIKit)
    @State private var feedbackGenerator: UIImpactFeedbackGenerator?
#endif

    private let activationEdgeWidth: CGFloat = 24
    private let requiredHorizontalTranslation: CGFloat = 45
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
                hasPreparedFeedback = false
#if canImport(UIKit)
                feedbackGenerator = nil
#endif
            }
    }

    private func handleGestureChange(_ value: DragGesture.Value) {
        prepareFeedbackIfNeeded(for: value)

        guard !hasTriggeredSwipe,
              let backButton = mainViewState.headerBackButton,
              value.startLocation.x <= activationEdgeWidth,
              value.translation.width > requiredHorizontalTranslation,
              abs(value.translation.height) < maximumVerticalTranslation else {
            return
        }

        hasTriggeredSwipe = true
        triggerFeedbackIfNeeded()
        let action = mainViewState.makeBackButtonAction(for: backButton, router: router)
        withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.86, blendDuration: 0.12)) {
            action()
        }
    }

    private func prepareFeedbackIfNeeded(for value: DragGesture.Value) {
#if canImport(UIKit)
        guard !hasTriggeredSwipe,
              !hasPreparedFeedback,
              value.startLocation.x <= activationEdgeWidth,
              value.translation.width > 0 else {
            return
        }

        if feedbackGenerator == nil {
            feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        }

        feedbackGenerator?.prepare()
        hasPreparedFeedback = true
#endif
    }

    private func triggerFeedbackIfNeeded() {
#if canImport(UIKit)
        feedbackGenerator?.impactOccurred()
        hasPreparedFeedback = false
#endif
    }
}

extension View {
    /// Enables the leading-edge swipe gesture that mirrors the header back button.
    func enableEdgeSwipeBackGesture() -> some View {
        modifier(EdgeSwipeBackModifier())
    }
}
