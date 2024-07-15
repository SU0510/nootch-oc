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
    
    let activitiesManager: ActiveLiveActivitiesManager
    
    private(set) var files = Set<TrayFile>() {
        willSet {
            doAfter { [weak self] in
                guard let self else { return }
                let newSelectedFiles = self.selectedFiles.intersection(newValue)
                if self.selectedFiles.count != newSelectedFiles.count {
                    self.selectedFiles = newSelectedFiles
                }
                let isTrayActive = self.activitiesManager.activeLiveActivities.contains(.tray)
                if newValue.isEmpty {
                    if isTrayActive {
                        self.activitiesManager.activeLiveActivities.remove(.tray)
                    }
                } else {
                    if !isTrayActive {
                        self.activitiesManager.activeLiveActivities.insert(.tray)
                    }
                }
            }
        }
    }
    private(set) var selectedFiles = Set<TrayFile>()
    private var pressedKeysEvent: NSEvent?
    
    private var isCommandPressed: Bool {
        guard let pressedKeysFlags = pressedKeysEvent?.modifierFlags else { return false }
        
        return pressedKeysFlags.contains(NSEvent.ModifierFlags.command)
    }
    private var isCombiningKeyPressed: Bool {
        guard let pressedKeysFlags = pressedKeysEvent?.modifierFlags else { return false }
        
        return pressedKeysFlags.contains(NSEvent.ModifierFlags.command) ||
                pressedKeysFlags.contains(NSEvent.ModifierFlags.shift)
    }
    
    init(activitiesManager: ActiveLiveActivitiesManager = .shared) {
        self.activitiesManager = activitiesManager
        setupEvents()
    }
    
    func setupEvents() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.pressedKeysEvent = event
            return event
        }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if accessEnabled {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self else { return event }
                if event.keyCode == 8 && self.isCommandPressed {
                    self.copySelectedFilesToClipboard()
                }
                return event
            }
        }
    }
    
    func removeFile(_ file: TrayFile) { _ = withAnimation(.smooth) { files.remove(file) } }
    func addFile(_ file: TrayFile) { _ = withAnimation(.smooth) { self.files.insert(file) } }
    func addFiles(_ newFiles: [TrayFile]) { withAnimation(.smooth) { self.files = self.files.union(newFiles) } }
    
    func addFilesFromURLs(_ fileURLs: [URL]) {
        let newFiles = fileURLs.concurrentMap { TrayFile(url: $0) }
        addFiles(newFiles)
    }
    
    func selectFile(_ file: TrayFile?) {
        guard let file else {
            selectedFiles.removeAll()
            return
        }
        
        if selectedFiles.contains(file) {
            if isCombiningKeyPressed {
                selectedFiles.remove(file)
            }
        } else {
            if !isCombiningKeyPressed {
                selectedFiles.removeAll()
            }
            selectedFiles.insert(file)
        }
    }
    
    func copySelectedFilesToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url }
        pasteboard.writeObjects(urls as [NSPasteboardWriting])
    }
}
