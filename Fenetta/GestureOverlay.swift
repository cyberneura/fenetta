import SwiftUI
import UIKit

/// Transparent UIKit view that owns every touch gesture on the viewer.
/// SwiftUI's DragGesture cannot tell one finger from two, so the two-finger pan
/// and the pinch live here and are allowed to run simultaneously.
struct GestureOverlay: UIViewRepresentable {
    var onSingleTap: () -> Void
    var onDoubleTap: () -> Void
    var onPinch: (_ scale: CGFloat, _ state: UIGestureRecognizer.State) -> Void
    var onTwoFingerPan: (_ translation: CGSize, _ state: UIGestureRecognizer.State) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let coordinator = context.coordinator

        let doubleTap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2

        let singleTap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleSingleTap))
        singleTap.require(toFail: doubleTap)

        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch))
        pinch.delegate = coordinator

        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = coordinator

        [doubleTap, singleTap, pinch, pan].forEach(view.addGestureRecognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var parent: GestureOverlay

        init(parent: GestureOverlay) {
            self.parent = parent
        }

        @objc func handleSingleTap() {
            parent.onSingleTap()
        }

        @objc func handleDoubleTap() {
            parent.onDoubleTap()
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            parent.onPinch(recognizer.scale, recognizer.state)
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let translation = recognizer.translation(in: recognizer.view)
            parent.onTwoFingerPan(CGSize(width: translation.x, height: translation.y), recognizer.state)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
