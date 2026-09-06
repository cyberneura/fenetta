import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewerState = ViewerState()
    @State private var gestureStartZoom = 1.0
    @State private var gestureStartPan: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            let viewport = geometry.size

            ZStack {
                Color.black

                preview(viewport: viewport)

                if let message = cameraManager.statusMessage {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "video.slash",
                        description: Text(message)
                    )
                    .foregroundStyle(.white)
                }

                GestureOverlay(
                    onSingleTap: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewerState.controlsVisible.toggle()
                        }
                    },
                    onDoubleTap: {
                        viewerState.toggleFitMode()
                    },
                    onPinch: { scale, state in
                        switch state {
                        case .began:
                            gestureStartZoom = viewerState.zoomScale
                        case .changed:
                            viewerState.setZoom(gestureStartZoom * scale)
                        default:
                            break
                        }
                    },
                    onTwoFingerPan: { translation, state in
                        switch state {
                        case .began:
                            gestureStartPan = viewerState.panOffset
                        case .changed:
                            viewerState.pan(by: translation, from: gestureStartPan)
                        default:
                            break
                        }
                    }
                )

                if viewerState.controlsVisible {
                    ControlsOverlay(cameraManager: cameraManager, viewerState: viewerState)
                        .transition(.opacity)
                }
            }
            .onChange(of: viewport, initial: true) {
                viewerState.updateLayout(viewport: viewport, videoSize: cameraManager.videoSize)
            }
            .onChange(of: cameraManager.videoSize) {
                viewerState.updateLayout(viewport: viewport, videoSize: cameraManager.videoSize)
            }
        }
        .ignoresSafeArea()
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .task {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
        .onChange(of: cameraManager.selectedDeviceID) {
            viewerState.resetZoom()
        }
    }

    // A sideways rotation swaps the preview's width and height before rotating,
    // so that contain/cover fitting is computed against the rotated frame.
    private func preview(viewport: CGSize) -> some View {
        let sideways = viewerState.isRotatedSideways
        return CameraPreviewView(session: cameraManager.session, videoGravity: viewerState.fitMode.videoGravity)
            .frame(
                width: sideways ? viewport.height : viewport.width,
                height: sideways ? viewport.width : viewport.height
            )
            .rotationEffect(viewerState.rotationAngle)
            .frame(width: viewport.width, height: viewport.height)
            .scaleEffect(viewerState.zoomScale)
            .offset(viewerState.panOffset)
            .clipped()
    }
}

#Preview {
    ContentView()
}
