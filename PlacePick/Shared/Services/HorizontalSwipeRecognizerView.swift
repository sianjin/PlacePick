import SwiftUI
import UIKit

/// A transparent overlay that recognizes a horizontal swipe even when placed over a
/// ScrollView full of Buttons (a Calendar day-cell grid, a month-picker grid). SwiftUI's own
/// gesture-priority modifiers (.gesture, .simultaneousGesture, .highPriorityGesture) only
/// arbitrate within SwiftUI's own gesture-composition tree — none of them can out-prioritize
/// a ScrollView's native UIScrollView.panGestureRecognizer, which is a sibling UIKit
/// recognizer outside that tree entirely. The one API that actually arbitrates against native
/// recognizers is UIGestureRecognizerDelegate, so this wraps a UIPanGestureRecognizer
/// directly.
///
/// `cancelsTouchesInView = false` on the pan recognizer, not a hitTest override, is what
/// actually lets both this recognizer AND the SwiftUI Button underneath receive the same
/// touch: a hitTest-based approach (returning nil to "pass through") was tried first and
/// broke the opposite way — since the recognizer never receives a touch its own view's
/// hitTest already rejected, it could never observe motion to decide the drag was
/// horizontal in the first place. Letting both recognizers see every touch, and only ever
/// firing onSwipe once a drag has clearly resolved as horizontal, is what lets a tap open a
/// day cell and a horizontal drag change the month, from the exact same overlay.
struct HorizontalSwipeRecognizerView: UIViewRepresentable {
    let onSwipe: (_ leftward: Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipe: onSwipe)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        let recognizer = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        recognizer.delegate = context.coordinator
        recognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSwipe = onSwipe
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSwipe: (_ leftward: Bool) -> Void
        private var didFire = false

        init(onSwipe: @escaping (_ leftward: Bool) -> Void) {
            self.onSwipe = onSwipe
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            switch recognizer.state {
            case .began:
                didFire = false
            case .changed:
                guard !didFire else { return }
                let translation = recognizer.translation(in: recognizer.view)
                guard abs(translation.x) > 24, abs(translation.x) > abs(translation.y) else { return }
                didFire = true
                onSwipe(translation.x < 0)
            default:
                break
            }
        }

        /// Lets this recognizer run alongside the ScrollView's own pan recognizer and every
        /// day-cell/month-cell Button's own tap recognizer, instead of blocking or being
        /// blocked by either.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
