//
//  TrayFile.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI
import SwiftDate

@Observable
class TrayFile: Hashable, Identifiable {
    static func == (lhs: TrayFile, rhs: TrayFile) -> Bool {
        lhs.id == rhs.id
    }
    
    private(set) var url: URL
    private(set) var id: String
    private(set) var nameTruncated: String
    private(set) var name: String

    let image: Image
    let addedAt: Date
    let isImage: Bool
    
    init(url: URL) {
        self.url = url
        id = url.absoluteString
        image = loadImgFromURL(url) ?? iconForFile(at: url)
        addedAt = Date()
        name = url.lastPathComponent
        nameTruncated = truncateFileName(url.lastPathComponent, maxLength: 16)
        isImage = url.isImg
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
    
    private func updateData(with url: URL) {
        self.url = url
        id = url.absoluteString
        name = url.lastPathComponent
        nameTruncated = truncateFileName(url.lastPathComponent, maxLength: 16)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
