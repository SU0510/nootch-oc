//
//  HUDManager.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//
// Researched from: https://www.reddit.com/r/MacOS/comments/l51olq/disable_volumebrightness_overlay_macos_big_sur/

import Foundation

struct HUDManager {
    private init() {}

    private static func executeProcess(at path: String, with arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
    }

    public static func enableSystemHUD() {
        do {
            try executeProcess(at: "/usr/bin/killall", with: ["-9", "OSDUIHelper"])
        } catch {
            print("Failed to enable OSDUIHelper.")
        }
    }

    public static func disableSystemHUD() {
        do {
            // if OSDUIHelper is not running, start the process
            try executeProcess(at: "/bin/launchctl", with: ["kickstart", "gui/\(getuid())/com.apple.OSDUIHelper"])
            usleep(250000)
            
            // kill to hide the HUD
            try executeProcess(at: "/usr/bin/killall", with: ["-STOP", "OSDUIHelper"])
        } catch {
            print("Failed to kill OSDUIHelper.")
        }
    }
}
