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

enum AudioDeviceType {
    case normal
    case airpodsMax
    case airpodsPro
    case airpods
    case unknown
}

struct SoundCoordinator {
    private init() {}
    
    static func getSoundVolume() throws -> Float {
        do {
            return try getStandardSoundVolume()
        } catch {
            throw SoundError.failed
        }
    }
    
    static func getAudioDeviceType() throws -> AudioDeviceType {
        do {
            return try getCurrentAudioDeviceType()
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
    
    private static func getCurrentAudioDeviceType() throws -> AudioDeviceType {
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
            print("Error getting default output device: \(status)")
            throw SoundError.failed
        }
        
        var deviceNameSize = UInt32(256)
        var deviceNameProperty = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMain))
        
        var deviceName: CFString = "" as CFString
        let deviceNameStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &deviceNameProperty,
            0,
            nil,
            &deviceNameSize,
            &deviceName)
        
        if deviceNameStatus != kAudioHardwareNoError {
            throw SoundError.failed
        }
        
        let deviceNameSwift = deviceName as String
        
        // Determine device type based on name (case-insensitive)
        let lowercasedName = deviceNameSwift.lowercased()
        if lowercasedName.contains("airpods max") {
            return .airpodsMax
        } else if lowercasedName.contains("airpods pro") {
            return .airpodsPro
        } else if lowercasedName.contains("airpods") {
            return .airpods
        } else if lowercasedName.contains("built-in") || lowercasedName.contains("internal") || lowercasedName.contains("speakers") {
            return .normal
        } else {
            print("Debug: Device type not recognized: \(deviceNameSwift)")
            return .unknown
        }
    }
}
