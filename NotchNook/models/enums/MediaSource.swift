//
//  MediaSource.swift
//  NotchNook
//
//  Created by Lori Montenegro on 25/06/25.
//

enum MediaSource: String, CaseIterable, Codable {
    case appleMusic = "com.apple.Music"
    case spotify = "com.spotify.client"
    case systemWide = "systemWide"
    
    var bundleIdentifier: String? {
        switch self {
            case .appleMusic, .spotify:
                return self.rawValue
            case .systemWide:
                return nil
        }
    }
    
    var name: String {
        switch self {
            case .appleMusic:
                return "\"Music\""
            case .spotify:
                return "\"Spotify\""
            case .systemWide:
                return ""
        }
    }
}
