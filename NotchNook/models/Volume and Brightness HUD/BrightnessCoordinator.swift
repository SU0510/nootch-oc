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

actor BrightnessCoordinator {
    private init() {}
    
    enum BrightnessError: Error {
        case standardMethodFailed
        case alternateMethodFailed
        case allMethodsFailed
    }
    
    static func getDisplayBrightness() async throws -> Float {
        do {
            return try await getStandardDisplayBrightness()
        } catch {
            return try await getAlternateDisplayBrightness()
        }
    }
    
    private static func getStandardDisplayBrightness() async throws -> Float {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var brightness: float_t = 1
                let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IODisplayConnect"))
                defer {
                    IOObjectRelease(service)
                }
                
                let result = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
                if result == kIOReturnSuccess {
                    continuation.resume(returning: brightness)
                } else {
                    continuation.resume(throwing: BrightnessError.standardMethodFailed)
                }
            }
        }
    }
    
    private static func getAlternateDisplayBrightness() async throws -> Float {
        let data = try await runCoreBrightnessDiag()
        return try await parseBrightness(from: data)
    }
    
    private static func runCoreBrightnessDiag() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/libexec/corebrightnessdiag")
                    task.arguments = ["status-info"]
                    let pipe = Pipe()
                    task.standardOutput = pipe
                    try task.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    task.waitUntilExit()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private static func parseBrightness(from data: Data) async throws -> Float {
        try await withCheckedThrowingContinuation { continuation in
            do {
                guard
                    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? NSDictionary,
                    let displays = plist["CBDisplays"] as? [String: [String: Any]]
                else {
                    throw BrightnessError.alternateMethodFailed
                }
                
                for display in displays.values {
                    if
                        let displayInfo = display["Display"] as? [String: Any],
                        displayInfo["DisplayServicesIsBuiltInDisplay"] as? Bool == true,
                        let brightness = displayInfo["DisplayServicesBrightness"] as? Float
                    {
                        continuation.resume(returning: brightness)
                        return
                    }
                }
                throw BrightnessError.alternateMethodFailed
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
