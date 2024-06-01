//
//  getDeviceSerialNumber.swift
//  NotchNook
//
//  Created by Igor Marcossi on 31/05/24.
//

import Foundation
import IOKit.ps

func getDeviceSerialNumber() -> String? {
    let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
    guard platformExpert > 0 else { return nil }
    
    let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
        .takeUnretainedValue()
    
    IOObjectRelease(platformExpert)
    return serialNumberAsCFString as? String
}
