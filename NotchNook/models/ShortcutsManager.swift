//
//  ShortcutsManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI
import Foundation

struct Shortcut: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

@Observable
class ShortcutsManager {
    static let shared = ShortcutsManager()
    var shortcuts: [Shortcut] = []
    
    private init() {
        shortcuts = self.fetchShortcuts().map { Shortcut(name: $0, icon: "sparkles") }
    }
    
    func runAppleScript(script: String) -> [String]? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if output.numberOfItems > 0 {
                var result: [String] = []
                for index in 1...output.numberOfItems {
                    if let item = output.atIndex(index)?.stringValue {
                        result.append(item)
                    }
                }
                return result
            }
        }
        return nil
    }
    
    let listProcessesScript = """
    tell application "System Events"
        return name of every process
    end tell
    """

    func listProcesses() -> [String] {
        if let processes = runAppleScript(script: listProcessesScript) {
            return processes
        }
        return []
    }
    
    func fetchShortcuts() -> [String] {

        let openCloseScript = """
        tell application "Shortcuts"
            set shortcutList to name of every shortcut
        end tell
        return shortcutList
        """

        // Check if Shortcuts was already open
        let wasOpenBefore = listProcesses().contains("Shortcuts")

        // Fetch the shortcuts
        let shortcuts = runAppleScript(script: openCloseScript) ?? []
        
        // Close Shortcuts if it was not open before
        if !wasOpenBefore {
            let closeScript = """
            tell application "Shortcuts" to quit
            """
            _ = runAppleScript(script: closeScript)
        }
        
        return shortcuts
    }
    
    func runShortcut(named name: String) {
        let script = """
        tell application "Shortcuts"
            run shortcut "\(name)"
        end tell
        """
        DispatchQueue.global(qos: .userInitiated).async {
            _ = self.runAppleScript(script: script)
        }
    }
}
