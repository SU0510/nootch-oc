import SwiftUI
import AVFoundation
import Defaults

struct MirrorWidgetView: View {
    var arrayPosition: ArrayPosition
    
    @State private var session: AVCaptureSession?
    @State private var mode = Mode.stopped
    @Environment(\.nookSettings) private var nookSettings
    enum Mode { case stopped, loading, mirrorring }
    
    private let width: Double
    
    init(arrayPosition: ArrayPosition) {
        self.arrayPosition = arrayPosition
        if case .unique(let size) = NookWidget.mirror.gridSizeType {
            self.width = size.width.screenPoints
        } else {
            self.width = Double(2 * NookGrid.point)
        }
    }
    
    var body: some View {
        Button(action: toggleCamera) {
            ZStack {
                cameraView
                overlayView
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: .infinity)
        }
        .paddingDependingOnArrPos(arrayPosition: arrayPosition, padding: nookSettings.widgetsPadding)
        .frame(width: width)
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
        .onAppear(perform: checkCameraPermission)
        .onDisappear(perform: stopCamera)
    }
    
    @ViewBuilder
    private var cameraView: some View {
        if mode == .mirrorring, let session = session {
            CameraPreview(session: session)
                .scaledToFill()
                .clipShape(Circle())
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
                        .foregroundStyle(.white.opacity(0.5))
                        .transition(.scaleAndBlur)
                    }
                }
                .clipShape(Circle())
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
            let session = AVCaptureSession()
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                return
            }
            
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                let output = AVCaptureVideoDataOutput()
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                session.startRunning()
                DispatchQueue.main.async {
                    self.session = session
                    completion()
                }
            } catch {
                print("Error setting up camera: \(error)")
            }
        }
    }
    
    private func stopCamera() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session?.stopRunning()
            
            // Remove inputs and outputs from the session
            self.session?.inputs.forEach { input in
                self.session?.removeInput(input as! AVCaptureInput)
            }
            self.session?.outputs.forEach { output in
                self.session?.removeOutput(output as! AVCaptureOutput)
            }
            
            DispatchQueue.main.async {
                self.session = nil  // Set the session to nil to release memory
                self.mode = .stopped
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
            layer = videoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> VideoPreviewView {
        return VideoPreviewView(session: session)
    }
    
    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        nsView.videoPreviewLayer.session = session
    }
}
