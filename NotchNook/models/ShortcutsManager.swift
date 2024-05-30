//
//  ShortcutsManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import Foundation
import SwiftUI

struct Shortcut: Identifiable, Hashable, Codable {
    var id: String { name }
    let name: String
    let icon: String
    var exists: Bool {
        ShortcutsManager.shared.shortcuts.contains(name)
    }
}

@Observable
class ShortcutsManager {
    static let shared = ShortcutsManager()
    var shortcuts = Set<String>()
    
    private init() {
        self.fetchShortcuts()
    }
    
    func fetchShortcuts() -> [String] {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["shortcuts", "list"]
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                shortcuts = Set(output.components(separatedBy: "\n").filter { !$0.isEmpty })
            }
        } catch {
            print("Failed to fetch shortcuts: \(error)")
        }

        return []
    }
    
    func runShortcut(named name: String) {
        let scriptContent = "#!/bin/sh\nshortcuts run '\(name)'"
        let tempScriptURL = FileManager.default.temporaryDirectory.appendingPathComponent("runShortcut.sh")
        
        do {
            // Write the script content to a temporary file
            try scriptContent.write(to: tempScriptURL, atomically: true, encoding: .utf8)
            
            // Make the script executable
            let processChmod = Process()
            processChmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
            processChmod.arguments = ["+x", tempScriptURL.path]
            try processChmod.run()
            processChmod.waitUntilExit()
            
            // Execute the script
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = [tempScriptURL.path]
            
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
            } else {
                print("Shortcut execution failed with status: \(process.terminationStatus)")
            }
        } catch {
            print("Failed to run shortcut: \(error)")
        }
        
        // Clean up the temporary script
        try? FileManager.default.removeItem(at: tempScriptURL)
    }
}
