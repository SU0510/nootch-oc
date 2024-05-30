import SwiftUI
import AVFoundation
import Defaults

struct MirrorWidgetView: View {
    var arrayPosition: ArrayPosition
    
    @State private var session: AVCaptureSession?
    @State private var mode = Mode.stopped
    @Default(.nookSettings) private var nookSettings
    enum Mode { case stopped, loading, mirrorring }
    
    
    var body: some View {
        Button {
            guard mode != .loading else { return }
            
            let prevMode = mode
            
            withAnimation(.smooth(extraBounce: 0.15)) {
                mode = prevMode != .stopped ? .stopped : .loading
            } completion: {
                if prevMode == .stopped {
                    setupCamera {
                        withAnimation(.smooth(extraBounce: 0.15)) {
                            mode = .mirrorring
                        }
                    }
                } else {
                    DispatchQueue.global(qos: .utility).async {
                        session?.stopRunning()
                    }
                }
            }
        } label: {
            ZStack {
                if mode == .mirrorring, let session = session {
                    CameraPreview(session: session)
                        .scaledToFill()
                        .clipShape(Circle())
                        .transition(.scaleAndBlur)
                }
                
                if mode != .mirrorring {
                    Color.selected
                        .overlay {
                            if mode == .loading {
                                ProgressView()
                                    .scaledToFit()
                                    .frame(16)
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
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: .infinity)
        }
        .padding(EdgeInsets(
            top: 0,
            leading: arrayPosition == .first ? 0 : nookSettings.widgetsPadding,
            bottom: 0,
            trailing: arrayPosition == .last ? 0 : nookSettings.widgetsPadding)
        )
        .buttonStyle(ShrinkOnClick(minSize: 0.925))
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                // Handle permission response if needed
            }
        case .restricted, .denied:
            // Handle restricted/denied permission
            break
        case .authorized:
            break
        @unknown default:
            break
        }
    }
    
    private func setupCamera(_ cb: (() -> ())? = nil) {
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
            self.session = session
            
            DispatchQueue.global(qos: .utility).async {
                session.startRunning()
                cb?()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
}

struct CameraPreview: NSViewRepresentable {
    class VideoPreviewView: NSView {
        override func makeBackingLayer() -> CALayer {
            return AVCaptureVideoPreviewLayer()
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.wantsLayer = true
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateNSView(_ nsView: VideoPreviewView, context: Context) {
        nsView.videoPreviewLayer.session = session
    }
}
