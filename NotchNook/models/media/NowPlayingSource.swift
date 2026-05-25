//
//  NowPlayingSource.swift
//  NotchNook
//
//  A lightweight value type describing one media source registered with the
//  system NowPlaying framework (i.e. anything surfaced by macOS Control Center
//  "Now Playing" — apps that publish to MPNowPlayingInfoCenter / MediaRemote).
//

import AppKit

struct NowPlayingSource: Identifiable, Equatable {
    /// Bundle identifier of the publishing app (e.g. "com.spotify.client").
    let bundleIdentifier: String
    /// Human-readable display name returned by MediaRemote (falls back to bundle ID).
    let displayName: String
    /// PID of the publishing process.
    let pid: Int32
    /// App icon resolved from the bundle. Lazy – cached after first access.
    var icon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
           let img = NSWorkspace.shared.icon(forFile: url.path) as NSImage? {
            return img
        }
        return NSImage(systemSymbolName: "music.note", accessibilityDescription: nil) ?? NSImage()
    }

    var id: String { bundleIdentifier }

    static func == (lhs: NowPlayingSource, rhs: NowPlayingSource) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}
