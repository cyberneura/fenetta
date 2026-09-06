import SwiftUI

struct ControlsOverlay: View {
    @ObservedObject var cameraManager: CameraManager
    @ObservedObject var viewerState: ViewerState

    var body: some View {
        VStack {
            HStack(spacing: 16) {
                cameraMenu
                Spacer()
                rotateButton
                fitButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding()

            Spacer()
        }
    }

    private var cameraMenu: some View {
        Menu {
            if cameraManager.devices.isEmpty {
                Text("No external cameras")
            } else {
                ForEach(cameraManager.devices) { device in
                    Button {
                        cameraManager.select(device)
                    } label: {
                        if device.id == cameraManager.selectedDeviceID {
                            Label(device.name, systemImage: "checkmark")
                        } else {
                            Text(device.name)
                        }
                    }
                }
            }
            Divider()
            Button("Refresh", systemImage: "arrow.clockwise") {
                cameraManager.refreshDevices()
            }
        } label: {
            Label(cameraManager.selectedDeviceName ?? "No camera", systemImage: "video")
                .lineLimit(1)
        }
    }

    private var rotateButton: some View {
        Button {
            viewerState.rotate()
        } label: {
            Label("\(viewerState.rotationSteps * 90)°", systemImage: "rotate.right")
        }
    }

    private var fitButton: some View {
        Button {
            viewerState.toggleFitMode()
        } label: {
            Label(
                viewerState.fitMode == .contain ? "Fit" : "Fill",
                systemImage: viewerState.fitMode == .contain
                    ? "arrow.down.right.and.arrow.up.left"
                    : "arrow.up.left.and.arrow.down.right"
            )
        }
    }
}
