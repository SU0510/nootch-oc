//
//  MediaAppMeta.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/05/24.
//

import Foundation
import SwiftUI

enum MediaAppMeta: String, Equatable, CaseIterable {
    case spotify = "Spotify"
    case appleMusic = "Apple Music"
    
    var localizedName: LocalizedStringKey { LocalizedStringKey(rawValue) }
    
    var icon: NSImage? { iconForApp(bundleID: self.bundleID) }
    
    var bundleID: String {
        return switch self {
        case .appleMusic: "com.apple.Music"
        case .spotify: "com.spotify.client"
        }
    }
    
    var notification: String {
        return switch self {
        case .appleMusic: "\(bundleID).playerInfo"
        case .spotify: "\(bundleID).PlaybackStateChanged"
        }
    }
}
