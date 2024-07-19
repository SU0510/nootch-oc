//
//  BrightnessCoordinator.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//
// Researched from: https://github.com/Hammerspoon/hammerspoon/issues/2668

import Foundation
import Cocoa
import IOKit.graphics

class BrightnessCoordinator {
    private init() {}
    
    private static var method = BrightnessMethod.standard
    
    private enum BrightnessMethod: Error {
        case standard
        case alternate
        case failed
    }
    
    static func getDisplayBrightness() throws -> Float {
        switch method {
        case .standard:
            do {
                return try getStandardDisplayBrightness()
            } catch {
                print("Standard method failed with error: \(error)")
                method = .alternate
            }
        case .alternate:
            do {
                return try getAlternateDisplayBrightness()
            } catch {
                print("Alternate method failed with error: \(error)")
                method = .failed
            }
        case .failed:
            throw BrightnessMethod.failed
        }
        return try getDisplayBrightness()
    }
    
    private static func getStandardDisplayBrightness() throws -> Float {
        var brightness: float_t = 1
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
        defer {
            IOObjectRelease(service)
        }
        
        let result = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        guard result == kIOReturnSuccess else {
            throw BrightnessMethod.standard
        }
        return brightness
    }
    
    private static func getAlternateDisplayBrightness() throws -> Float {
        let data = try runCoreBrightnessDiag()
        return try parseBrightness(from: data)
    }
    
    private static func runCoreBrightnessDiag() throws -> Data {
        let task = Process()
        task.launchPath = "/usr/libexec/corebrightnessdiag"
        task.arguments = ["status-info"]
        let pipe = Pipe()
        task.standardOutput = pipe
        try task.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        return data
    }
    
    private static func parseBrightness(from data: Data) throws -> Float {
        guard
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary,
            let displays = plist["CBDisplays"] as? [String: [String: Any]]
        else {
            throw BrightnessMethod.alternate
        }
        
        for display in displays.values {
            if
                let displayInfo = display["Display"] as? [String: Any],
                displayInfo["DisplayServicesIsBuiltInDisplay"] as? Bool == true,
                let brightness = displayInfo["DisplayServicesBrightness"] as? Float
            {
                return brightness
            }
        }
        throw BrightnessMethod.alternate
    }
}
