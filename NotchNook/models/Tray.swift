//
//  Tray.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import Cocoa

@Observable
class Tray {
    private var tempDirectory: URL?
    private var folderMonitor: FolderMonitor?
    private(set) var files = Set<TrayFile>() {
        willSet {
            let newSelectedFiles = selectedFiles.intersection(newValue)
            if selectedFiles.count != newSelectedFiles.count { 
                doAfter { self.selectedFiles = newSelectedFiles }
            }
            doAfter {
                if newValue.isEmpty {
                    if LiveActivitiesManager.shared.activeLiveActivities.contains(.tray) {
                        LiveActivitiesManager.shared.activeLiveActivities.remove(.tray)
                    }
                } else {
                    if !LiveActivitiesManager.shared.activeLiveActivities.contains(.tray) {
                        LiveActivitiesManager.shared.activeLiveActivities.insert(.tray)
                    }
                }
            }
        }
    }
    private(set) var selectedFiles = Set<TrayFile>()
    private var pressedKeysEvent: NSEvent?
    var isCombiningKeyPressed: Bool {
        return (pressedKeysEvent?.modifierFlags.contains(NSEvent.ModifierFlags.command) ?? false ||
                pressedKeysEvent?.modifierFlags.contains(NSEvent.ModifierFlags.shift) ?? false)
    }
    
    init() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleKeyEvent(event: event)
            return event
        }
    }
    
    func removeFile(_ file: TrayFile) { _ = withAnimation(.smooth) { self.files.remove(file) } }
    func addFile(_ file: TrayFile) { _ = withAnimation(.smooth) { self.files.insert(file) } }
    func addFiles(_ newFiles: [TrayFile]) { withAnimation(.smooth) { self.files = self.files.union(newFiles) } }
    
    func addFilesFromURLs(_ fileURLs: [URL]) {
        let newFiles = fileURLs.concurrentMap { TrayFile(url: $0) }
        addFiles(newFiles)
    }
    
    func selectFile(_ file: TrayFile?) {
        if let file {
            if self.selectedFiles.contains(file) {
                if isCombiningKeyPressed {
                    self.selectedFiles.remove(file)
                }
            } else {
                if !isCombiningKeyPressed {
                    self.selectedFiles.removeAll()
                }
                self.selectedFiles.insert(file)
            }
        } else {
            self.selectedFiles.removeAll()
        }
    }
    
    private func handleKeyEvent(event: NSEvent) { pressedKeysEvent = event }
}
