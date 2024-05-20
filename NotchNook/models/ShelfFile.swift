//
//  ShelfFile.swift
//  NotchNook
//
//  Created by Igor Marcossi on 18/05/24.
//

import SwiftUI

@Observable
class ShelfFile: Equatable, Hashable, Identifiable {
    static func == (lhs: ShelfFile, rhs: ShelfFile) -> Bool {
        lhs.url.absoluteString == rhs.url.absoluteString
    }
    
    var id: String {
        self.url.absoluteString
    }
    var image: Image
    var url: URL
    var addedAt: Date
    
    var name: String { self.url.lastPathComponent }
    
    var nameTruncated: String { truncateFileName(self.name, maxLength: 16) }
    
    init(url: URL) {
        self.image = iconForFile(at: url)
        self.url = url
        self.addedAt = Date()
    }
    
    func remove() {
        NotchNook.shared.shelf.removeFile(self)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
