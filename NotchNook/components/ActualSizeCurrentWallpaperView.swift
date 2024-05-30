//
//  ActualSizeCurrentWallpaperView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct ActualSizeCurrentWallpaperView: View {
    var body: some View {
        GeometryReader { geo in
            if let wallpaper = CurrentWallpaperManager.shared.currentWallpaper {
                wallpaper
                    .resizable()
                    .frame(width: NSScreen.main?.frame.width ?? 1920, height: NSScreen.main?.frame.height ?? 1080)
                    .frame(geo.size, .top)
                    .clipped()
                    .allowsHitTesting(false)
            }
        }
    }
}
