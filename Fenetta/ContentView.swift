import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var gestureStartZoom = 1.0

    var body: some View {
        NavigationSplitView {
            DevicePickerView(cameraManager: cameraManager)
                .navigationTitle("Cameras")
        } detail: {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                CameraPreviewView(session: cameraManager.session)
                    .scaleEffect(cameraManager.zoomScale)
                    .clipped()
                    .gesture(
                        MagnificationGesture()
                            .onChanged { magnification in
                                cameraManager.setZoom(gestureStartZoom * magnification)
                            }
                            .onEnded { _ in
                                gestureStartZoom = cameraManager.zoomScale
                            }
                    )

                if let message = cameraManager.statusMessage {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "video.slash",
                        description: Text(message)
                    )
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle(cameraManager.selectedDeviceName ?? "Fenetta")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}

#Preview {
    ContentView()
}

