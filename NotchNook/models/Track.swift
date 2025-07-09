//
//  Track.swift
//  NotchNook
//
//  Created by Igor Marcossi on 23/05/24.
//

import SwiftUI

struct Track: Equatable, Hashable, Identifiable {
    static let empty = Track(title: String(localized: "Unknown Title"), artist: String(localized: "Unknown Artist"), album: String(localized: "Unknown Album"))
    
    static func == (lhs: Track, rhs: Track) -> Bool {
        lhs.id == rhs.id
    }
    
    var id: String { metaId + albumId + mediaApp.bundleId }
    var metaId: String { title + artist + album + String(describing: loved) }
    var albumId: String { artist + album + String(describing: albumArt.isValid) + String(describing: albumArt.size) }
    var title = ""
    var artist = ""
    var album = ""
    var appName = ""
    var loved: Bool?
    var mediaApp = SystemAppMeta()
    var albumArt = NSImage()
    var browserBundleId: String?
    var appBundleId = ""
    
    @MainActor
    var albumArtAverageColor: NSColor {
        return albumArt.averageColor() ?? .nonShockingWhite
    }
    
    func isValidReplacement(_ track: Track) -> Bool {
        return self.metaId != track.metaId || self.mediaApp != track.mediaApp || (!self.albumArt.isValid && track.albumArt.isValid)
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(self.id)
    }
}
