import AVFoundation
import SwiftUI

enum FitMode: String {
    case contain
    case cover

    var videoGravity: AVLayerVideoGravity {
        switch self {
        case .contain: .resizeAspect
        case .cover: .resizeAspectFill
        }
    }

    var toggled: FitMode {
        self == .contain ? .cover : .contain
    }
}

@MainActor
final class ViewerState: ObservableObject {
    static let minZoom = 1.0
    static let maxZoom = 5.0

    @AppStorage("fitMode") var fitMode: FitMode = .contain
    @AppStorage("rotationSteps") var rotationSteps = 0

    @Published private(set) var zoomScale = 1.0
    @Published private(set) var panOffset: CGSize = .zero
    @Published var controlsVisible = false

    var rotationAngle: Angle {
        .degrees(Double(rotationSteps) * 90)
    }

    var isRotatedSideways: Bool {
        rotationSteps % 2 == 1
    }

    func rotate() {
        rotationSteps = (rotationSteps + 1) % 4
        panOffset = clamped(panOffset)
    }

    func toggleFitMode() {
        fitMode = fitMode.toggled
        panOffset = clamped(panOffset)
    }

    /// Screen-space size of the viewport and native pixel size of the current video.
    /// Both are needed to know how far the zoomed picture may be dragged.
    func updateLayout(viewport: CGSize, videoSize: CGSize?) {
        self.viewport = viewport
        self.videoSize = videoSize
        panOffset = clamped(panOffset)
    }

    func setZoom(_ scale: CGFloat) {
        zoomScale = min(max(scale, Self.minZoom), Self.maxZoom)
        panOffset = clamped(panOffset)
    }

    func pan(by translation: CGSize, from start: CGSize) {
        let proposed = CGSize(width: start.width + translation.width, height: start.height + translation.height)
        panOffset = clamped(proposed)
    }

    func resetZoom() {
        zoomScale = 1.0
        panOffset = .zero
    }

    private var viewport: CGSize = .zero
    private var videoSize: CGSize?

    /// Size of the visible picture (before zoom), in screen axes.
    /// In cover mode the preview layer crops the video to its frame, so the visible
    /// picture is exactly the viewport. In contain mode it is smaller than the viewport
    /// along one axis, so the pan limit must come from the picture rather than from the viewport.
    var displayedVideoSize: CGSize {
        guard fitMode == .contain, let videoSize, videoSize.width > 0, videoSize.height > 0 else {
            return viewport
        }
        // Fitting happens in the preview's own frame, whose axes are swapped when rotated sideways.
        let frame = isRotatedSideways
            ? CGSize(width: viewport.height, height: viewport.width)
            : viewport
        let scale = min(frame.width / videoSize.width, frame.height / videoSize.height)
        let fitted = CGSize(width: videoSize.width * scale, height: videoSize.height * scale)
        return isRotatedSideways ? CGSize(width: fitted.height, height: fitted.width) : fitted
    }

    // The picture may be dragged only until its edge reaches the viewport edge.
    // A picture that fits inside the viewport along an axis cannot move on that axis.
    private func clamped(_ offset: CGSize) -> CGSize {
        let picture = displayedVideoSize
        let maxX = max(0, (picture.width * zoomScale - viewport.width) / 2)
        let maxY = max(0, (picture.height * zoomScale - viewport.height) / 2)
        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}
