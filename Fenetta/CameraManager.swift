import AVFoundation
import Combine
import Foundation

struct CameraDevice: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class CameraManager: ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var devices: [CameraDevice] = []
    @Published var selectedDeviceID: String? {
        didSet {
            guard selectedDeviceID != oldValue else { return }
            configureSession(for: selectedDeviceID)
        }
    }
    @Published private(set) var statusMessage: String? = "Connect a USB camera to begin."
    @Published private(set) var videoSize: CGSize?

    private let sessionQueue = DispatchQueue(label: "camera.session")
    private var observers: [NSObjectProtocol] = []
    private var hasStarted = false

    var selectedDeviceName: String? {
        devices.first(where: { $0.id == selectedDeviceID })?.name
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        observeDeviceChanges()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            refreshDevices()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self else { return }
                    if granted {
                        self.refreshDevices()
                    } else {
                        self.statusMessage = "Camera access is required. Enable it in Settings."
                    }
                }
            }
        case .denied, .restricted:
            statusMessage = "Camera access is required. Enable it in Settings."
        @unknown default:
            statusMessage = "Camera access is unavailable."
        }
    }

    func stop() {
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    func select(_ device: CameraDevice) {
        selectedDeviceID = device.id
    }

    func refreshDevices() {
        // Keep only stable identifiers. AVCaptureDevice objects are deliberately
        // rediscovered whenever the hardware list or selection changes.
        let discoveredDevices = Self.discoverExternalCameras().map {
            CameraDevice(id: $0.uniqueID, name: $0.localizedName)
        }
        devices = discoveredDevices

        let currentIsAvailable = discoveredDevices.contains { $0.id == selectedDeviceID }
        let nextID = currentIsAvailable ? selectedDeviceID : discoveredDevices.first?.id

        if selectedDeviceID == nextID {
            configureSession(for: nextID)
        } else {
            selectedDeviceID = nextID
        }

        if discoveredDevices.isEmpty {
            statusMessage = "Connect a USB camera to begin."
        }
    }

    private func observeDeviceChanges() {
        let center = NotificationCenter.default
        for name in [AVCaptureDevice.wasConnectedNotification, AVCaptureDevice.wasDisconnectedNotification] {
            let observer = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshDevices()
                }
            }
            observers.append(observer)
        }
    }

    private func configureSession(for deviceID: String?) {
        sessionQueue.async { [weak self, session] in
            guard let self else { return }

            session.beginConfiguration()
            session.inputs.forEach(session.removeInput)

            guard let deviceID,
                  let device = Self.discoverExternalCameras().first(where: { $0.uniqueID == deviceID }) else {
                session.commitConfiguration()
                if session.isRunning { session.stopRunning() }
                Task { @MainActor in
                    self.statusMessage = "Connect a USB camera to begin."
                    self.videoSize = nil
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else {
                    throw CameraError.cannotAddInput
                }
                session.addInput(input)
                session.commitConfiguration()
                if !session.isRunning { session.startRunning() }
                let dimensions = CMVideoFormatDescriptionGetDimensions(device.activeFormat.formatDescription)
                let videoSize = CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
                Task { @MainActor in
                    self.statusMessage = nil
                    self.videoSize = videoSize
                }
            } catch {
                session.commitConfiguration()
                if session.isRunning { session.stopRunning() }
                Task { @MainActor in
                    self.statusMessage = "Unable to use this camera: \(error.localizedDescription)"
                }
            }
        }
    }

    nonisolated private static func discoverExternalCameras() -> [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.external],
            mediaType: .video,
            position: .unspecified
        ).devices
    }
}

private enum CameraError: LocalizedError {
    case cannotAddInput

    var errorDescription: String? {
        "The selected camera cannot be added to the capture session."
    }
}
