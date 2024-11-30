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
    
    private var sessions: [String: (session: AVCaptureSession, output: AVCaptureVideoDataOutput)] = [:]
    
    init() {
        let allDevices = getCaptureDeviceList()
        self.allDevices = allDevices
        let defaultDeviceID = Defaults[.defaultMirrorDevice]
        self.selectedDevice = allDevices.first(where: { $0.uniqueID == defaultDeviceID }) ?? allDevices.first
    }
    
    deinit {
        for widgetID in sessions.keys {
            stopRunning(for: widgetID)
        }
        sessions.removeAll()
    }
    
    func captureSession(for widgetID: String) -> AVCaptureSession {
        if let existingSession = sessions[widgetID]?.session {
            return existingSession
        }
        
        let newSession = AVCaptureSession()
        let videoOutput = AVCaptureVideoDataOutput()
        sessions[widgetID] = (newSession, videoOutput)
        return newSession
    }
    
    func setupSession(for widgetID: String, deviceID: String) {
        guard let device = allDevices.first(where: { $0.uniqueID == deviceID }) else { return }
        
        let (captureSession, videoOutput) = sessions[widgetID] ?? (AVCaptureSession(), AVCaptureVideoDataOutput())
        
        captureSession.beginConfiguration()
        
        captureSession.inputs.forEach { captureSession.removeInput($0) }
        captureSession.outputs.forEach { captureSession.removeOutput($0) }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Error setting up input for widget \(widgetID): \(error)")
        }
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        let videoConnection = videoOutput.connection(with: .video)
        videoConnection?.isVideoMirrored = Defaults[.mirrorCameraInputWhenAvail]
        
        captureSession.commitConfiguration()
        
        sessions[widgetID] = (captureSession, videoOutput)
        
        startSession(for: widgetID)
    }
    
    func stopRunning(for widgetID: String) {
        guard let (captureSession, videoOutput) = sessions[widgetID] else { return }
        
        if captureSession.isRunning {
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            captureSession.commitConfiguration()
            captureSession.stopRunning()
        }
        
        videoOutput.setSampleBufferDelegate(nil, queue: nil)
        sessions.removeValue(forKey: widgetID)
    }
    
    private func startSession(for widgetID: String) {
        guard let (captureSession, _) = sessions[widgetID], !captureSession.isRunning else { return }
        captureSession.startRunning()
    }
    
    func isVideoMirroringSupported(for widgetID: String) -> Bool {
        return sessions[widgetID]?.output.connection(with: .video)?.isVideoMirroringSupported ?? false
    }
}
