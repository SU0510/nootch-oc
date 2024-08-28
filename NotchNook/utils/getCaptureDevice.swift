//
//  getCaptureDevice.swift
//  NotchNook
//
//  Created by Hasan Sultan on 7/29/24.
//
import AVFoundation

func getCaptureDeviceList () -> [AVCaptureDevice] {
    let videoCaptureDevice = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.continuityCamera, .external, .builtInWideAngleCamera], mediaType: .video, position: .unspecified)
    
    if videoCaptureDevice.devices.isEmpty {
        return []
    }
    return videoCaptureDevice.devices
    
}

