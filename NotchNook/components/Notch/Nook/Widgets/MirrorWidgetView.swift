import SwiftUI
import AVFoundation
import Defaults

struct MirrorWidgetView: View {
    
    enum Mode {
        case stopped, loading, mirrorring
    }
    
    @State private var mode = Mode.stopped
    
    var arrayPosition: ArrayPosition
    var isSettingsPreview: Bool
    
    @Environment(\.nookSettings) private var nookSettings
    @Environment(\.cameraManager) private var cameraManager
    @Environment(\.generalSettings) private var generalSettings
    
    init(arrayPosition: ArrayPosition, isSettingsPreview: Bool = false) {
        self.arrayPosition = arrayPosition
        self.isSettingsPreview = isSettingsPreview
    }
    
    var body: some View {
        Group {
            if isSettingsPreview {
                previewContent
            } else {
                Button(action: toggleCamera) {
                    previewContent
                }
                .buttonStyle(ShrinkOnClick(minSize: 0.925))
            }
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookSettings.widgetsPadding)
        .onAppear(perform: isSettingsPreview ? setupPreviewCamera : checkCameraPermission)
        .onDisappear(perform: stopCamera)
        .onChange(of: cameraManager.selectedDevice) {
            if isSettingsPreview {
                withAnimation(.bouncySmooth) {
                    mode = .loading
                }
                doAfter() {
                    self.setupPreviewCamera()
                }
            }
        }
    }

    
    @ViewBuilder
    private var previewContent: some View {
        ZStack {
            cameraView
            overlayView
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    @ViewBuilder
    private var cameraView: some View {
        if mode == .mirrorring {
            CameraPreview(session: cameraManager.captureSession, mirrorVideo: cameraManager.mirrorVideo)
                .scaledToFill()
                .mask {
                    if generalSettings.preferRoundButtons {
                        Circle().fill(.black)
                    } else {
                        RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black)
                    }
                }
                .transition(.scaleAndBlur)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if mode != .mirrorring {
            Color.selected
                .overlay {
                    if mode == .loading {
                        ProgressView()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .opacity(0.5)
                            .transition(.scaleAndBlur)
                    } else {
                        VStack(spacing: 0) {
                            Image(systemName: NookWidget.mirror.icon)
                                .font(.system(size: 24, weight: .medium))
                            Text(NookWidget.mirror.name)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.nonShockingWhite.opacity(0.5))
                        .transition(.scaleAndBlur)
                    }
                }
                .mask {
                    if generalSettings.preferRoundButtons {
                        Circle().fill(.black)
                    } else {
                        RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black)
                    }
                }
                .transition(.scaleAndBlur)
        }
    }
    
    private func toggleCamera() {
        guard mode != .loading else { return }
        
        let prevMode = mode
        
        withAnimation(.bouncySmooth) {
            mode = prevMode != .stopped ? .stopped : .loading
        } completion: {
            if prevMode == .stopped {
                setupCamera {
                    withAnimation(.bouncySmooth) {
                        mode = .mirrorring
                    }
                }
            } else {
                stopCamera()
            }
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        case .restricted, .denied, .authorized:
            break
        @unknown default:
            break
        }
    }
    
    private func setupCamera(_ completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            cameraManager.setupSession()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    private func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.cameraManager.stopRunning()
            
            DispatchQueue.main.async {
                self.mode = .stopped
            }
        }
    }
    
    private func setupPreviewCamera() {
        checkCameraPermission()
        setupCamera {
            withAnimation(.bouncySmooth) {
                mode = .mirrorring
            }
        }
    }

}

struct CameraPreview: NSViewRepresentable {
    class VideoPreviewView: NSView {
        var videoPreviewLayer: AVCaptureVideoPreviewLayer!
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            setupLayer(session: session)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupLayer(session: AVCaptureSession) {
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            if let connection = videoPreviewLayer.connection, connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
            layer = videoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    let mirrorVideo: Bool
    
    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView(session: session)
        view.wantsLayer = true
        doAfter {
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
            self.updateMirroring(for: view)
        }
        return view
    }
    
    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        doAfter {
            nsView.videoPreviewLayer.session = self.session
            self.updateMirroring(for: nsView)
        }
    }
    
    private func updateMirroring(for view: VideoPreviewView) {
        doAfter {
            if view.videoPreviewLayer.connection?.isVideoMirroringSupported == true {
                view.videoPreviewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                view.videoPreviewLayer.connection?.isVideoMirrored = self.mirrorVideo
            }
        }
    }
}
