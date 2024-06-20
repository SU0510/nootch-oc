//
//  FolderMonitor.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/06/24.
//

import Foundation

class FolderMonitor {
    private var monitorSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let queue = DispatchQueue.global()

    init(path: String, callback: @escaping () -> Void) {
        fileDescriptor = open(path, O_EVTONLY)
        if fileDescriptor != -1 {
            monitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: queue)
            monitorSource?.setEventHandler(handler: callback)
            monitorSource?.setCancelHandler {
                close(self.fileDescriptor)
            }
        }
    }

    func start() {
        monitorSource?.resume()
    }

    func stop() {
        monitorSource?.cancel()
        monitorSource = nil
    }

    deinit {
        stop()
    }
}
