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
    
    var selectedDevice: AVCaptureDevice?
    var captureSession = AVCaptureSession()
    var mirrorVideo: Bool = false
    var isVideoMirroringSupported: Bool = true
    
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var videoConnection: AVCaptureConnection?
    
    init() {
        guard 
            Defaults[.defaultMirrorDevice] != "",
            let device = getDeviceFromDefaults(uniqueID: Defaults[.defaultMirrorDevice])
        else {
            initDevice()
            return
        }
            
        self.selectedDevice = device
        self.mirrorVideo = Defaults[.mirrorVideoForDevice]
    }
    
    private func initDevice () {
        let allDevicesAvailForCapture = getCaptureDeviceList()
        if allDevicesAvailForCapture.isEmpty {
            // No devices exist for capture
            Defaults[.defaultMirrorDevice] = ""
            selectedDevice = nil
            mirrorVideo = false
            isVideoMirroringSupported = false
            return
        } else {
            // First time opening application
            selectedDevice = allDevicesAvailForCapture.first
            saveDeviceToDefaults(device: selectedDevice!)
        }
    }
    
    private func getDeviceFromDefaults(uniqueID: String) -> AVCaptureDevice? {
        let devices = getCaptureDeviceList()
        return devices.first { $0.uniqueID == uniqueID }
    }
    
    func saveDeviceToDefaults(device: AVCaptureDevice) {
        Defaults[.defaultMirrorDevice] = device.uniqueID
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
        
        if let connection = videoOutput.connection(with: .video) {
            videoConnection = connection
            
            doAfter {
                self.isVideoMirroringSupported = self.videoConnection!.isVideoMirroringSupported
            }
        }
        
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
    
    func updateMirrorSettingsForVideoDevice() {
        doAfter {
            Defaults[.mirrorVideoForDevice] = self.mirrorVideo
            self.updateVideoConnection()
        }
    }
    
    private func updateVideoConnection() {
        doAfter {
            if let connection = self.videoConnection, connection.isVideoMirroringSupported {
                connection.isVideoMirrored = self.mirrorVideo
            }
        }
    }
}
