//
//  Track.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

struct Track: Equatable, Hashable {
    static let empty = Track(title: "Unknown Title", artist: "Unknown Artist", album: "Unknown Album")
    
//    static func == (lhs: Track, rhs: Track) -> Bool {
//        lhs.title == rhs.title && lhs.artist == rhs.artist && lhs.album == rhs.album
//    }
    var title: String
    var artist: String
    var album: String
    var loved: Bool?
    var albumArt = NSImage()
    
    init(
        title: String = "",
        artist: String = "",
        album: String = "",
        loved: Bool? = nil,
        albumArt: NSImage = NSImage()
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.loved = loved
        self.albumArt = albumArt
    }
    
//    public func hash(into hasher: inout Hasher) {
//      hasher.combine(self.title)
//      hasher.combine(self.artist)
//      hasher.combine(self.album)
//    }
}
