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
        var cb: (([URL]) -> ()) = tray.addFilesFromURLs
        let dropAction = allDropActions.first(where: { $0.id == state.hoveredDropTargetID })
        var hasFiles = false
        let loadItemGroup = DispatchGroup()
        
        if !isTray, let dropAction {
            cb = { urls in
                dropAction.action(urls, .zero)
            }
        }
        
        let pasteboard = info.draggingPasteboard
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL], !fileURLs.isEmpty {
            hasFiles = true
            DispatchQueue.main.async {
                cb(fileURLs)
            }
        }
        
        guard let promiseReceivers = info.draggingPasteboard.readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil) as? [NSFilePromiseReceiver] else {
            finishDragging(close: true)
            return false
        }
        
        let randomDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: randomDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        
        for receiver in promiseReceivers {
            hasFiles = true
            loadItemGroup.enter()
            receiver.receivePromisedFiles(atDestination: randomDirectoryURL, options: [:], operationQueue: OperationQueue()) { fileURL, error in
                defer { loadItemGroup.leave() }
                if let error = error {
                    print("Error receiving file: \(error)")
                } else {
                    DispatchQueue.main.async {
                        cb([fileURL])
                    }
                }
            }
        }
        
        loadItemGroup.notify(queue: .main) {
            finishDragging(close: !hasFiles && !isTray)
        }
        
        return true
    }
}
