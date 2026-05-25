//
//  TrayFile.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import SwiftDate
import Combine

@Observable
class TrayFile {
    
    private(set) var url: URL
    private(set) var inode: UInt64?
    private(set) var nameTruncated: String
    
    /// Stable identity used both for SwiftUI ForEach and as the Identifiable.id.
    let id: UUID

    /// When non-nil, this file was dropped as part of a multi-file gesture and belongs
    /// to the visual stack identified by this UUID. Files sharing the same stackID are
    /// rendered as a single collapsed stack chip. Assigned by Tray.addFilesFromURLs
    /// when >= 2 files arrive in one call.
    var stackID: UUID?

    var name: String {
        didSet {
            guard oldValue != name else { return }
            rename(to: name)
        }
    }

    let image: Image
    let addedAt: Date
    let isImage: Bool
    
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    
    init(url: URL, stackID: UUID? = nil) {
        self.url = url
        self.id = UUID()
        self.stackID = stackID
        image = loadImgFromURL(url) ?? iconForFile(at: url)
        addedAt = Date()
        name = url.lastPathComponent
        nameTruncated = truncateFileName(url.lastPathComponent, maxLength: 16)
        isImage = url.isImg
        inode = getInode(url)
        startObservingFileChanges()
    }
    
    deinit {
        stopObservingFileChanges()
    }
    
    func rename(to newName: String) {
        let fileManager = FileManager.default
        let originalURL = self.url
        let newBaseName = newName.components(separatedBy: ".").first ?? newName
        let newURL = originalURL
            .deletingLastPathComponent()
            .appendingPathComponent(newBaseName)
            .appendingPathExtension(originalURL.pathExtension)

        do {
            try fileManager.moveItem(at: originalURL, to: newURL)
            updateData(with: newURL)
        } catch {
            print("Failed to rename file: \(error)")
        }
    }
    
    /// To be called when the rename is done externally
    private func updateFileName() {
        let fileManager = FileManager.default
        let parentDirectory = url.deletingLastPathComponent()
        do {
            let files = try fileManager.contentsOfDirectory(at: parentDirectory, includingPropertiesForKeys: [.fileResourceIdentifierKey])
            if let newFile = files.first(where: { getInode($0) == self.inode }) {
                DispatchQueue.main.async {
                    self.updateData(with: newFile)
                }
            }
        } catch {
            print("Failed to update file name: \(error)")
        }
    }
    
    private func updateData(with url: URL) {
        self.url = url
        inode = getInode(url)
        name = url.lastPathComponent
        nameTruncated = truncateFileName(url.lastPathComponent, maxLength: 16)
    }
    
    private func startObservingFileChanges() {
        fileDescriptor = open(url.deletingLastPathComponent().path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        fileSystemSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: DispatchQueue.main)

        fileSystemSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.updateFileName()
        }

        fileSystemSource?.setCancelHandler {
            close(self.fileDescriptor)
        }

        fileSystemSource?.resume()
    }
    
    private func stopObservingFileChanges() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
    }
    
    private func getInode(_ url: URL) -> UInt64? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attributes?[.systemFileNumber] as? UInt64
    }
}

extension TrayFile: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(inode)
    }
}

extension TrayFile: Identifiable {
    // id is declared on the class itself (UUID).
    static func == (lhs: TrayFile, rhs: TrayFile) -> Bool {
        lhs.inode == rhs.inode
    }
}
