import SwiftUI
import UIKit

/// Re-enables the left-edge swipe-back gesture for an entire `NavigationStack`.
///
/// `NavigationStack` gives you the interactive pop gesture for free — except
/// UIKit disables it on any screen that hides the navigation bar
/// (`.toolbar(.hidden, for: .navigationBar)`), which several of our full-bleed
/// screens do. This installs a permissive delegate on the stack's shared
/// `interactivePopGestureRecognizer`, so the swipe works on every pushed
/// destination regardless of whether that screen shows a nav bar.
///
/// Apply once to a `NavigationStack`'s root content via `.enableSwipeBack()`.
private struct SwipeBackEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Proxy { Proxy() }
    func updateUIViewController(_ controller: Proxy, context: Context) {}

    final class Proxy: UIViewController, UIGestureRecognizerDelegate {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            gesture.delegate = self
            gesture.isEnabled = true
        }

        // Only fire when there's actually a screen to pop back to — otherwise the
        // gesture can wedge the stack on the root view.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            (navigationController?.viewControllers.count ?? 0) > 1
        }
    }
}

extension View {
    /// Enables left-edge swipe-back for the enclosing `NavigationStack`, even on
    /// destinations that hide the navigation bar. Attach to the stack's root content.
    func enableSwipeBack() -> some View {
        background(SwipeBackEnabler())
    }
}
