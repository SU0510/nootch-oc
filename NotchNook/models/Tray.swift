//
//  Tray.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import Cocoa
import Quartz

@Observable
class Tray {
    
    private enum KeyCode: UInt16 {
        case c = 8
        case spaceBar = 49
    }
    
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
        
        return pressedKeysFlags.contains(.command)
    }
    private var isCombiningKeyPressed: Bool {
        guard let pressedKeysFlags = pressedKeysEvent?.modifierFlags else { return false }
        
        return pressedKeysFlags.contains(.command) ||
                pressedKeysFlags.contains(.shift)
    }
    
    // MARK: - Initialization
    
    init(activitiesManager: ActiveLiveActivitiesManager = .shared) {
        self.activitiesManager = activitiesManager
        setupTempDirectory()
        setupFolderMonitor()
        setupEvents()
    }
    
    // MARK: - Setup methods
    
    private func setupTempDirectory() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("TrayFiles", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
            tempDirectory = tempDir
        } catch {
            print("Failed to create temp directory")
        }
    }
    
    func setupFolderMonitor() {
        guard let tempDirectory else { return }
        folderMonitor = FolderMonitor(path: tempDirectory.path()) { [weak self] in
            doAfter { self?.updateFiles() }
        }
        folderMonitor?.start()
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
                if event.keyCode == KeyCode.spaceBar.rawValue {
                    self.quickLookSelectedFiles()
                    return nil
                } else if event.keyCode == KeyCode.c.rawValue && self.isCommandPressed {
                    self.copySelectedFilesToClipboard()
                    return nil
                }
                return event
            }
        }
    }
    
    // MARK: Handling files methods
    
    func removeFile(_ file: TrayFile) { _ = withAnimation(.smooth) { files.remove(file) } }
    func addFile(_ file: TrayFile) { _ = withAnimation(.smooth) { files.insert(file) } }
    func addFiles(_ newFiles: [TrayFile]) { withAnimation(.smooth) { files = files.union(newFiles) } }
    
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
    
    private func copySelectedFilesToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url }
        pasteboard.writeObjects(urls as [NSPasteboardWriting])
    }
    
    func openSelectedFiles() {
        let fileURLs = selectedFiles.map { $0.url }
        for url in fileURLs {
            NSWorkspace.shared.open(url)
        }
    }

    private func quickLookSelectedFiles() {
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.makeKeyAndOrderFront(nil)
    }
    
    private func updateFiles() {
        let fileManager = FileManager.default
        let currentURLs = files.map { $0.url }
        var updatedFiles = Set<TrayFile>()

        guard let directory = tempDirectory else { return }
        let existingFiles = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        for file in files {
            let fileExists = existingFiles?.contains(where: { $0.lastPathComponent == file.url.lastPathComponent }) ?? false
            if fileExists {
                updatedFiles.insert(file)
            } else {
                if let newURL = findExistingFile(for: file.url) {
                    updatedFiles.insert(TrayFile(url: newURL))
                }
            }
        }

        DispatchQueue.main.async {
            self.files = updatedFiles
        }
    }
    
    private func findExistingFile(for oldURL: URL) -> URL? {
        guard let directory = oldURL.deletingLastPathComponent() as URL?,
              let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return nil }
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent != oldURL.lastPathComponent && fileURL.deletingPathExtension().lastPathComponent == oldURL.deletingPathExtension().lastPathComponent {
                return fileURL
            }
        }
        return nil
    }
    
}

extension Tray: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        return selectedFiles.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        return selectedFiles[selectedFiles.index(selectedFiles.startIndex, offsetBy: index)].url as QLPreviewItem
    }
}
