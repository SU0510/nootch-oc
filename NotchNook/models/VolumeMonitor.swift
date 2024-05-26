//
//  VolumeMonitor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import SwiftUI
import Foundation
import AudioToolbox

@Observable
class VolumeMonitor {
    static let shared = VolumeMonitor()
    var volume: CGFloat = 0.0

    private init() {
        setupVolumeMonitoring()
    }

    deinit {
        removeVolumeMonitoring()
    }

    private func setupVolumeMonitoring() {
        let defaultOutputDeviceID = getDefaultOutputDeviceID()
        var volumeProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )

        let callback: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.updateVolume()
        }

        AudioObjectAddPropertyListenerBlock(defaultOutputDeviceID, &volumeProperty, nil, callback)
        
        // Initial volume fetch
        updateVolume()
    }

    private func removeVolumeMonitoring() {
        let defaultOutputDeviceID = getDefaultOutputDeviceID()
        var volumeProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )

        AudioObjectRemovePropertyListenerBlock(defaultOutputDeviceID, &volumeProperty, nil, { _, _ in })
    }

    private func getDefaultOutputDeviceID() -> AudioObjectID {
        var defaultOutputDeviceID = AudioObjectID(kAudioObjectSystemObject)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        var dataSize = UInt32(MemoryLayout<AudioObjectID>.size)
        AudioObjectGetPropertyData(defaultOutputDeviceID, &propertyAddress, 0, nil, &dataSize, &defaultOutputDeviceID)
        return defaultOutputDeviceID
    }

    private func updateVolume() {
        let defaultOutputDeviceID = getDefaultOutputDeviceID()
        var volumeProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
        var volume: Float32 = 0.0
        var dataSize = UInt32(MemoryLayout<Float32>.size)
        AudioObjectGetPropertyData(defaultOutputDeviceID, &volumeProperty, 0, nil, &dataSize, &volume)

        self.volume = CGFloat(Float(volume))
    }
}
