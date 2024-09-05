//
//  CameraManager.swift
//  NotchNook
//
//  Created by Hasan Sultan on 7/30/24.
//

import AVFoundation
import Defaults
import SwiftUI

@Observable
class CameraManager {
    
    var allDevices: [AVCaptureDevice] = []
    var selectedDevice: AVCaptureDevice? {
        didSet {
            guard let uniqueID = selectedDevice?.uniqueID else {
                Defaults[.defaultMirrorDevice] = ""
                return
            }
            Defaults[.defaultMirrorDevice] = uniqueID
        }
    }
    var captureSession = AVCaptureSession()
    var mirrorVideo: Bool {
        didSet {
            Defaults[.mirrorVideoForDevice] = mirrorVideo
            if let connection = videoConnection, connection.isVideoMirroringSupported {
                connection.isVideoMirrored = mirrorVideo
            }
        }
    }
    var isVideoMirroringSupported: Bool {
        videoConnection?.isVideoMirroringSupported ?? false
    }
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private var videoConnection: AVCaptureConnection?
    
    init() {
        let allDevices = getCaptureDeviceList()
        self.allDevices = allDevices
        let defaultDeviceID = Defaults[.defaultMirrorDevice]
        self.selectedDevice = allDevices.first(where: { $0.uniqueID == defaultDeviceID }) ?? allDevices.first
        self.mirrorVideo = Defaults[.mirrorVideoForDevice]
    }
    
    func setupSession() {
        guard let selectedDevice = selectedDevice else { return }
        
        captureSession.beginConfiguration()
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        
        do {
            let input = try AVCaptureDeviceInput(device: selectedDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting up input: \(error)")
        }
        
        if captureSession.outputs.contains(videoOutput){
            captureSession.removeOutput(videoOutput)
        }
        
        captureSession.addOutput(videoOutput)
        
        videoConnection = videoOutput.connection(with: .video)
        
        captureSession.commitConfiguration()
        startSession()
    }
    
    public func stopRunning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
    }
    
    private func startSession(){
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }
}
