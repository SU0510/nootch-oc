//
//  NotchNook.swift
//  Notchway
//
//  Created by Igor Marcossi on 13/05/24.
//

import Foundation
import SwiftUI

@Observable
class NotchNook {
    static let shared = NotchNook()
    
    var shelf = Shelf()
    var pinned = false
}

@Observable
class Shelf {
    var files = Set<ShelfFile>()
    
    func removeFile(_ file: ShelfFile) {
        files.remove(file)
    }
}

struct ShelfFile: Equatable, Hashable, Identifiable {
    var id: String {
        self.url.absoluteString
    }
    var image: Image
    var url: URL
    
    init(url: URL) {
        self.image = iconForFile(at: url)
        self.url = url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
