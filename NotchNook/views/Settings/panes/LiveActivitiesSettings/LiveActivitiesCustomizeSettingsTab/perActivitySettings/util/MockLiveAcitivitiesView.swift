//
//  MockLiveAcitivitiesView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct MockLiveAcitivitiesView: View {
    var activities: Set<NotchNook.LiveActivity>
    var body: some View {
        ZStack(alignment: .top) {
            MockTopBar(liveActivities: activities)
                .background {
                    NotchShape(notchHeight: NotchShape.usualNotchHeight).offset(y: -1).fill(.black)
                }
                .clipShape(NotchShape(notchHeight: NotchShape.usualNotchHeight).offset(y: -1))
        }
        .animation(.smooth(extraBounce: 0.15), value: activities)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .top)
        .background {
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
