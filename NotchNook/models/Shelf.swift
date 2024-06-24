//
//  Shelf.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import Cocoa

@Observable
class Shelf {
    static var shared: Shelf { NotchNook.shared.shelf }
    
    private var tempDirectory: URL?
    private var folderMonitor: FolderMonitor?
    private(set) var files = Set<ShelfFile>() {
        willSet {
            let newSelectedFiles = selectedFiles.intersection(newValue)
            if selectedFiles.count != newSelectedFiles.count { 
                doThisAfter(0) { self.selectedFiles = newSelectedFiles }
            }
            doThisAfter(0) {
                if newValue.isEmpty {
                    if NotchNook.shared.activeLiveActivities.contains(.shelf) {
                        NotchNook.shared.activeLiveActivities.remove(.shelf)
                    }
                } else {
                    if !NotchNook.shared.activeLiveActivities.contains(.shelf) {
                        NotchNook.shared.activeLiveActivities.insert(.shelf)
                    }
                }
            }
        }
    }
    private(set) var selectedFiles = Set<ShelfFile>()
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
    
    func removeFile(_ file: ShelfFile) { _ = withAnimation(.smooth) { self.files.remove(file) } }
    func addFile(_ file: ShelfFile) { _ = withAnimation(.smooth) { self.files.insert(file) } }
    func addFiles(_ newFiles: [ShelfFile]) { withAnimation(.smooth) { self.files = self.files.union(newFiles) } }
    
    func addFilesFromURLs(_ fileURLs: [URL]) {
        let newFiles = fileURLs.concurrentMap { ShelfFile(url: $0) }
        addFiles(newFiles)
    }
    
    func selectFile(_ file: ShelfFile?) {
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

extension Shelf {
    func setupTemporaryDirectory() {
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        guard let tempDirectory else { return }
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        
        folderMonitor = FolderMonitor(path: tempDirectory.path) {
            self.updateFilesFromTemporaryDirectory()
        }
        folderMonitor?.start()
    }

    private func updateFilesFromTemporaryDirectory() {
        guard let tempDirectory else { return }
        DispatchQueue.main.async {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
                self.files = Set(fileURLs.map { ShelfFile(url: $0) })
            } catch {
                print("Error updating files from temporary directory: \(error)")
            }
        }
    }
    
    func addFileFromData(_ data: Data, filename: String) {
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        FileManager.default.createFile(atPath: destinationURL.path, contents: data, attributes: nil)
        let newFile = ShelfFile(url: destinationURL)
        addFile(newFile)
    }
}
