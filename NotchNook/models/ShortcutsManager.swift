//
//  ShortcutsManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/05/24.
//

import SwiftUI
import Foundation

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
    
    func fetchShortcuts() {

        let openCloseScript = """
        tell application "Shortcuts"
            set shortcutList to name of every shortcut
        end tell
        return shortcutList
        """

        // Check if Shortcuts was already open
        let wasOpenBefore = listProcesses().contains("Shortcuts")

        // Fetch the shortcuts
        shortcuts = Set(runAppleScript(script: openCloseScript) ?? [])
        
        // Close Shortcuts if it was not open before
        if !wasOpenBefore {
            let closeScript = """
            tell application "Shortcuts" to quit
            """
            _ = runAppleScript(script: closeScript)
        }
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
