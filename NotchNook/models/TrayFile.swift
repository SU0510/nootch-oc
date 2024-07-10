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
    
    let url: URL
    let id: String
    let image: Image
    let addedAt: Date
    let nameTruncated: String
    let isImage: Bool
    
    init(url: URL) {
        self.url = url
        id = url.absoluteString
        image = loadImgFromURL(url) ?? iconForFile(at: url)
        addedAt = Date()
        nameTruncated = truncateFileName(url.lastPathComponent, maxLength: 16)
        isImage = url.isImg
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
