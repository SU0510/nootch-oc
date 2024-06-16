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
    
    private(set) var files = Set<ShelfFile>() {
        willSet {
            let newSelectedFiles = selectedFiles.intersection(newValue)
            if selectedFiles.count != newSelectedFiles.count { 
                doThisAfter(0) { self.selectedFiles = newSelectedFiles }
            }
            doThisAfter(0) {
                withAnimation(TopBarView.animation) {
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

