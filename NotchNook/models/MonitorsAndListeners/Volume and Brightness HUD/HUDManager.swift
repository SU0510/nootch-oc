//
//  HUDManager.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/19/24.
//
// Researched from: https://www.reddit.com/r/MacOS/comments/l51olq/disable_volumebrightness_overlay_macos_big_sur/

import Foundation
import os.log

struct HUDManager {
    private init() {}

    private static let lock = NSLock()
    private static let log = OSLog(subsystem: "fi.lo.NotchNook", category: "HUDManager")

    // MARK: - Internal helpers

    @discardableResult
    private static func executeProcess(at path: String, with arguments: [String]) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        try process.run()
        process.waitUntilExit()
        return process.terminationStatus
    }

    /// Returns true if at least one OSDUIHelper process is found running.
    private static func isOSDRunning() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "OSDUIHelper"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return process.terminationStatus == 0 && !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            os_log("[HUDManager] pgrep failed: %{public}@", log: log, type: .error, error.localizedDescription)
            return false
        }
    }

    // MARK: - Public API

    /// Re-enables the system HUD by killing any running OSDUIHelper so launchd restarts it fresh.
    /// No-ops if the process is not running.
    public static func enableSystemHUD() {
        lock.lock()
        defer { lock.unlock() }

        guard isOSDRunning() else {
            os_log("[HUDManager] enableSystemHUD: OSDUIHelper not running, nothing to kill", log: log, type: .debug)
            return
        }
        do {
            try executeProcess(at: "/usr/bin/killall", with: ["-9", "OSDUIHelper"])
            os_log("[HUDManager] enableSystemHUD: sent SIGKILL to OSDUIHelper", log: log, type: .info)
        } catch {
            os_log("[HUDManager] enableSystemHUD failed: %{public}@", log: log, type: .error, error.localizedDescription)
        }
    }

    /// Stops the system HUD overlay by ensuring OSDUIHelper is running then SIGSTOPping it.
    /// Retries up to 3 times with 100ms backoff, verifying STOP via pgrep each time.
    /// Blocks the calling thread (run off main queue if latency matters).
    public static func disableSystemHUD() {
        lock.lock()
        defer { lock.unlock() }

        let maxAttempts = 3
        for attempt in 1...maxAttempts {
            os_log("[HUDManager] disableSystemHUD attempt %d/%d", log: log, type: .info, attempt, maxAttempts)

            // Kick OSDUIHelper so launchd makes sure it's alive before we STOP it.
            do {
                try executeProcess(at: "/bin/launchctl", with: [
                    "kickstart", "gui/\(getuid())/com.apple.OSDUIHelper"
                ])
            } catch {
                os_log("[HUDManager] kickstart failed (attempt %d): %{public}@", log: log, type: .error, attempt, error.localizedDescription)
            }

            // Brief pause so launchd can actually spawn the process.
            usleep(100_000) // 100ms

            // Send SIGSTOP.
            do {
                try executeProcess(at: "/usr/bin/killall", with: ["-STOP", "OSDUIHelper"])
                os_log("[HUDManager] SIGSTOP sent (attempt %d)", log: log, type: .info, attempt)
            } catch {
                os_log("[HUDManager] killall -STOP failed (attempt %d): %{public}@", log: log, type: .error, attempt, error.localizedDescription)
            }

            // Verify: pgrep returning 0 means at least one process exists (STOPPED counts).
            // We just need to confirm it's no longer responding — presence is enough.
            if isOSDRunning() {
                os_log("[HUDManager] OSDUIHelper confirmed stopped/present after attempt %d", log: log, type: .info, attempt)
                return
            }

            os_log("[HUDManager] OSDUIHelper not confirmed after attempt %d, retrying...", log: log, type: .default, attempt)
            if attempt < maxAttempts {
                usleep(100_000) // 100ms backoff before retry
            }
        }

        os_log("[HUDManager] disableSystemHUD: exhausted %d attempts, OSDUIHelper may not be suppressed", log: log, type: .error, maxAttempts)
    }
}
