//
//  SoundManager.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//
// Researched from: https://developer.apple.com/documentation/coreaudio/kaudioobjectpropertyelementmain

import Foundation
import CoreAudio
import AudioToolbox

private enum SoundError: Error {
    case failed
}

class SoundCoordinator {
    private init() {}
    
    static func getSoundVolume() throws -> Float {
        do {
            return try getStandardSoundVolume()
        } catch {
            throw SoundError.failed
        }
    }
    
    private static func getStandardSoundVolume() throws -> Float {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))
        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)
        
        if status != kAudioHardwareNoError {
            throw SoundError.failed
        }
        
        var volume: Float32 = 0.0
        var volumeSize = UInt32(MemoryLayout.size(ofValue: volume))
        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        let volumeStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &volume)
        
        if volumeStatus != kAudioHardwareNoError {
            throw SoundError.failed
        }
        
        return volume
    }
}

