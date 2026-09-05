import SwiftUI

struct DevicePickerView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        List(selection: Binding(
            get: { cameraManager.selectedDeviceID },
            set: { newValue in
                guard let newValue,
                      let device = cameraManager.devices.first(where: { $0.id == newValue }) else { return }
                cameraManager.select(device)
            }
        )) {
            if cameraManager.devices.isEmpty {
                ContentUnavailableView(
                    "No External Cameras",
                    systemImage: "video.slash",
                    description: Text("Connect a UVC camera using USB-C.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section("Available Cameras") {
                    ForEach(cameraManager.devices) { device in
                        Label(device.name, systemImage: "video")
                            .tag(device.id)
                    }
                }
            }
        }
        .refreshable {
            cameraManager.refreshDevices()
        }
    }
}

