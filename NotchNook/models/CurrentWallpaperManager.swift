//
//  CurrentWallpaperManager.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

@Observable
class CurrentWallpaperManager {
    static let shared = CurrentWallpaperManager()
    var currentWallpaper: Image?
    
    init() { self.updateCurrentWallpaper() }
    
    func updateCurrentWallpaper() {
        guard let screen = NSScreen.main else {
            print("No main screen available")
            return
        }

        guard let wallpaperUrl = NSWorkspace.shared.desktopImageURL(for: screen) else {
            print("No wallpaper set for the main screen")
            return
        }
        
        if let nsImg = NSImage(contentsOf: wallpaperUrl) {
            currentWallpaper = Image(nsImage: nsImg)
        }
    }
}
