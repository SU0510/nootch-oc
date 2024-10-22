//
//  performDrop.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.ShapeModifier {
    func performDrop(info: NSDraggingInfo) -> Bool {
        if state.trialOver { return false }
        
        let isTray = state.hoveredDropTargetID == TrayView.id
        let dropAction = allPipelines.first(where: { $0.id == state.hoveredDropTargetID })
        let fileManager = FileManager.default
        let appTempDir = fileManager.temporaryDirectory.appendingPathComponent("NotchNookTemp")
        let callBack: ([URL]) -> Void = { urls in
            if !isTray, let dropAction {
                dropAction.action(urls, .zero)
                cleanupTemporaryDirectory(appTempDir)
            } else {
                tray.addFilesFromURLs(urls)
            }
        }
        
        var hasFiles = false
        let loadItemGroup = DispatchGroup()
        
        let pasteboard = info.draggingPasteboard
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL], !fileURLs.isEmpty {
            hasFiles = true
            DispatchQueue.main.async {
                let processedURLs = fileURLs.compactMap { originalURL -> URL? in
                    if originalURL.path.contains(NSTemporaryDirectory()) {
                        return handleTemporaryFile(originalURL, fileManager, appTempDir)
                    } else {
                        return originalURL
                    }
                }
                callBack(processedURLs)
            }
        }
        
        guard let promiseReceivers = info.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] else {
            finishDragging(close: true)
            return false
        }
        
        for receiver in promiseReceivers {
            hasFiles = true
            loadItemGroup.enter()
            do {
                try fileManager.createDirectory(at: appTempDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating app temp directory: \(error)")
            }
            receiver.receivePromisedFiles(atDestination: appTempDir, options: [:], operationQueue: OperationQueue()) { fileURL, error in
                defer { loadItemGroup.leave() }
                if let error = error {
                    print("Error receiving file: \(error)")
                } else {
                    DispatchQueue.main.async {
                        callBack([fileURL])
                    }
                }
            }
        }
        
        loadItemGroup.notify(queue: .main) {
            finishDragging(close: !hasFiles && !isTray)
        }
        
        return true
    }
    
    private func handleTemporaryFile(_ originalURL: URL, _ fileManager: FileManager, _ appTempDir: URL) -> URL? {
        do {
            try fileManager.createDirectory(at: appTempDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating app temp directory: \(error)")
        }
        
        let newURL = appTempDir.appendingPathComponent(originalURL.lastPathComponent)
        do {
            try fileManager.moveItem(at: originalURL, to: newURL)
            return newURL
        } catch {
            print("Error moving file: \(error)")
            return nil
        }
    }
}
