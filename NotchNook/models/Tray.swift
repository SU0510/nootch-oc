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
    var editingFile: (file: TrayFile, newName: String)?
    
    private enum KeyCode: UInt16 {
        case a = 0
        case c = 8
        case spaceBar = 49
        case returnKey = 36
        case esc = 53
        case delete = 51
        case leftArrow = 123
        case rightArrow = 124
    }
    
    private var tempDirectory: URL?
    private var folderMonitor: FolderMonitor?
    
    let activitiesManager: ActiveLiveActivitiesManager
    
    private(set) var files = [TrayFile]() {
        willSet {
            let newSelectedFiles = selectedFiles.filter { newValue.contains($0) }
            if selectedFiles.count != newSelectedFiles.count {
                selectedFiles = newSelectedFiles
            }
            let isTrayActive = activitiesManager.activeLiveActivities.contains(.tray)
            if newValue.isEmpty {
                if isTrayActive {
                    activitiesManager.activeLiveActivities.remove(.tray)
                }
            } else {
                if !isTrayActive {
                    activitiesManager.activeLiveActivities.insert(.tray)
                }
            }
        }
    }
    private(set) var selectedFiles = [TrayFile]()
    private var baseFileIndex: Int?
    private var lastSelectedIndex: Int?
    private var pressedKeysEvent: NSEvent?
    
    private var isCommandPressed: Bool {
        NSEvent.modifierFlags.contains(.command)
    }
    private var isShiftPressed: Bool {
        NSEvent.modifierFlags.contains(.shift)
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
    
    private func setupFolderMonitor() {
        guard let tempDirectory else { return }
        folderMonitor = FolderMonitor(path: tempDirectory.path()) { [weak self] in
            DispatchQueue.main.async { self?.updateFiles() }
        }
        folderMonitor?.start()
    }
    
    private func setupEvents() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.pressedKeysEvent = event
            return event
        }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        guard accessEnabled else { return }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard 
                let self = self,
                let keyCode = KeyCode(rawValue: event.keyCode)
            else { return event }
            
            if editingFile != nil {
                return handleEditingKeys(event: event, key: keyCode)
            } else {
                return handleNonEditingKeys(event: event, key: keyCode)
            }
        }
    }
    
    func rename() {
        guard let editingFile = editingFile else { return }
        editingFile.file.rename(to: editingFile.newName)
        self.editingFile = nil
    }
    
    // MARK: Keys handling
    
    private func handleEditingKeys(event: NSEvent, key: KeyCode) -> NSEvent? {
        guard selectedFiles.count == 1 else { return event }
        
        switch key {
            case .returnKey:
                rename()
                return nil
                
            case .esc:
                editingFile = nil
                return nil
                
            default: return event
        }
    }
    
    private func handleNonEditingKeys(event: NSEvent, key: KeyCode) -> NSEvent? {
        switch key {
            case .a where isCommandPressed:
                selectAllFiles()
                return nil
                
            case .c where isCommandPressed:
                copySelectedFilesToClipboard()
                return nil
                
            case .spaceBar:
                toggleQuickLookState()
                return nil
                
            case .returnKey:
                if let file = selectedFiles.first, selectedFiles.count == 1 {
                    editingFile = (file, file.name)
                }
                return nil
                
            case .delete:
                removeSelectedFiles()
                return nil
                
            case .leftArrow, .rightArrow:
                let direction = key == .leftArrow ? -1 : 1
                if NSEvent.modifierFlags.contains(.shift) {
                    self.handleShiftArrowSelection(direction: direction)
                } else {
                    self.selectAdjacentFile(direction: direction)
                }
                return nil
                
            default: return event
        }
    }
    
    private func handleShiftArrowSelection(direction: Int) {
        guard !files.isEmpty else { return }
        
        if selectedFiles.isEmpty {
            lastSelectedIndex = 0
            selectedFiles = [files[0]]
        } else if lastSelectedIndex == nil {
            lastSelectedIndex = files.firstIndex(of: selectedFiles.last ?? files[0])
        }
        
        guard let currentIndex = lastSelectedIndex else { return }
        
        let newIndex = max(0, min(files.count - 1, currentIndex + direction))
        lastSelectedIndex = newIndex
        
        if baseFileIndex == nil {
            baseFileIndex = currentIndex
        }
        
        if let baseIndex = baseFileIndex {
            let rangeToSelect = min(baseIndex, newIndex)...max(baseIndex, newIndex)
            selectedFiles = Array(files[rangeToSelect])
        }
    }
    
    // MARK: Handling files methods
    
    func removeFile(_ file: TrayFile) {
        withAnimation(.smooth) {
            files.removeAll { $0 == file }
            selectedFiles.removeAll { $0 == file }
            baseFileIndex = nil
        }
    }
    
    private func addFile(_ file: TrayFile) {
        withAnimation(.smooth) {
            if !files.contains(file) {
                files.append(file)
            }
        }
    }
    
    func selectFile(_ file: TrayFile?) {
        guard let file else {
            selectedFiles.removeAll()
            baseFileIndex = nil
            lastSelectedIndex = nil
            return
        }
        
        if isShiftPressed {
            if let baseIndex = baseFileIndex, let currentIndex = files.firstIndex(of: file) {
                let rangeToSelect = min(baseIndex, currentIndex)...max(baseIndex, currentIndex)
                selectedFiles = Array(files[rangeToSelect])
                lastSelectedIndex = currentIndex
            } else {
                selectedFiles = [file]
                baseFileIndex = files.firstIndex(of: file)
                lastSelectedIndex = baseFileIndex
            }
        } else if isCommandPressed {
            if let index = selectedFiles.firstIndex(of: file) {
                selectedFiles.remove(at: index)
            } else {
                selectedFiles.append(file)
            }
            baseFileIndex = files.firstIndex(of: file)
            lastSelectedIndex = baseFileIndex
        } else {
            selectedFiles = [file]
            baseFileIndex = files.firstIndex(of: file)
            lastSelectedIndex = baseFileIndex
        }
        
        editingFile = nil
    }
    
    private func selectAdjacentFile(direction: Int) {
        guard !files.isEmpty else { return }
        
        let currentIndex = selectedFiles.isEmpty ? 0 : (files.firstIndex(of: selectedFiles.last!) ?? 0)
        let newIndex = max(0, min(files.count - 1, currentIndex + direction))
        
        selectFile(files[newIndex])
    }
    
    private func selectAllFiles() {
        selectedFiles = files
        baseFileIndex = 0
        lastSelectedIndex = files.count - 1
    }
    
    func openFile(_ file: TrayFile) {
        NSWorkspace.shared.open(file.url)
    }
    
    func removeSelectedFiles(currentFile: TrayFile? = nil) {
        withAnimation(.smooth) {
            guard let currentFile, !selectedFiles.contains(currentFile) else {
                files.removeAll { selectedFiles.contains($0) }
                selectedFiles.removeAll()
                baseFileIndex = nil
                return
            }
            removeFile(currentFile)
        }
    }
    
    func addFilesFromURLs(_ fileURLs: [URL]) {
        let newFiles = fileURLs.concurrentMap { TrayFile(url: $0) }
        for file in newFiles { self.addFile(file) }
    }
    
    func copySelectedFilesToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let urls = selectedFiles.map { $0.url }
        pasteboard.writeObjects(urls as [NSPasteboardWriting])
    }
    
    func airdropSelectedFiles() {
        airDropFiles(urls: selectedFiles.map { $0.url })
    }

    private func toggleQuickLookState() {
        guard let panel = QLPreviewPanel.shared() else { return }
        
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.dataSource = self
            panel.makeKeyAndOrderFront(nil)
        }
    }
    
    private func updateFiles() {
        DispatchQueue.global().async {
            let fileManager = FileManager.default
            var updatedFiles = [TrayFile]()
            
            guard let directory = self.tempDirectory else { return }
            let existingFiles = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            
            for file in self.files {
                let fileExists = existingFiles?.contains(where: { $0.lastPathComponent == file.url.lastPathComponent }) ?? false
                if fileExists {
                    updatedFiles.append(file)
                } else {
                    if let newURL = self.findExistingFile(for: file.url) {
                        updatedFiles.append(TrayFile(url: newURL))
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.files = updatedFiles
            }
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

// MARK: - QuickLook Datasource

extension Tray: QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        selectedFiles.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        selectedFiles[selectedFiles.index(selectedFiles.startIndex, offsetBy: index)].url as QLPreviewItem
    }
}
