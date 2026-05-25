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

    private var monitoredDeviceID: AudioObjectID = kAudioObjectUnknown
    private var volumeListenerBlock: AudioObjectPropertyListenerBlock?
    private var defaultDeviceListenerBlock: AudioObjectPropertyListenerBlock?

    private init() {
        setupVolumeMonitoring()
    }

    deinit {
        removeVolumeMonitoring()
    }

    private func setupVolumeMonitoring() {
        // Listen for default output device changes on the system object
        let deviceSwitchBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.rebindVolumeListener()
        }
        defaultDeviceListenerBlock = deviceSwitchBlock
        var defaultDeviceProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceProperty, nil, deviceSwitchBlock)

        // Bind the volume listener to the current default device
        bindVolumeListener(to: getDefaultOutputDeviceID())

        // Initial volume fetch
        updateVolume()
    }

    private func bindVolumeListener(to deviceID: AudioObjectID) {
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.updateVolume()
        }
        volumeListenerBlock = block
        monitoredDeviceID = deviceID
        var volumeProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
        AudioObjectAddPropertyListenerBlock(deviceID, &volumeProperty, nil, block)
    }

    private func unbindVolumeListener() {
        guard monitoredDeviceID != kAudioObjectUnknown, let block = volumeListenerBlock else { return }
        var volumeProperty = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster
        )
        AudioObjectRemovePropertyListenerBlock(monitoredDeviceID, &volumeProperty, nil, block)
        volumeListenerBlock = nil
        monitoredDeviceID = kAudioObjectUnknown
    }

    private func rebindVolumeListener() {
        unbindVolumeListener()
        let newDeviceID = getDefaultOutputDeviceID()
        bindVolumeListener(to: newDeviceID)
        updateVolume()
    }

    private func removeVolumeMonitoring() {
        // Unregister volume listener
        unbindVolumeListener()

        // Unregister default-device-change listener
        if let block = defaultDeviceListenerBlock {
            var defaultDeviceProperty = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultOutputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster
            )
            AudioObjectRemovePropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &defaultDeviceProperty, nil, block)
            defaultDeviceListenerBlock = nil
        }
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
