//
//  TopBarContentView.swift
//  NotchNook
//
//  Created by Lori Montenegro on 11/07/25.
//

import SwiftUI

struct TopBarContentView: View {
    
    var isLeft: Bool
    var scaleX: Double
    var scaleY: Double
    var isScreenInFullscreen: Bool = false
    
    @Environment(\.notchNook) private var notchNook
    @Environment(\.notchSize) private var notchSize
    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.traySettings) private var traySettings
    @Environment(\.nookWidgetsWidth) private var nookWidgetsWidth
    @Environment(\.openSettings) private var openSettings
    @Environment(\.nookSettings) private var nookSettings
    
    private var liveActivities: Set<LiveActivity> {
        let all = ActiveLiveActivitiesManager.shared.activeLiveActivities
        guard isScreenInFullscreen else { return all }
        return all.subtracting(liveActivitiesSettings.liveActivitiesHiddenInFullscreen)
    }
    
    private var collapsed: Bool {
        let width = notchNook.mode == .nook ? nookWidgetsWidth : traySettings.size.width
        return width < .init(9)
    }
    
    var body: some View {
        Group {
            switch notchNook.mode {
                case .closed:
                    LiveActivityView(side: isLeft ? .left : .right, activeActivities: liveActivities)
                        .frame(width: TopBarView.liveActionWidth)
                    
                case .dragging:
                    EmptyView()
                    
                case .nook, .tray:
                    if isLeft {
                        TopBarTabsView(collapsed: collapsed)
                            .frame(width: collapsed ? TopBarView.collapsedTopBarHalfWidth : nil, alignment: .leading)
                    } else {
                        HStack(spacing: 2) {
                            if !nookSettings.enabledWidgets.contains(.media) && !collapsed {
                                MiniPlayerView()
                            }
                            
                            CircleButton(icon: "gearshape.fill", iconSize: 13) {
                                openSettings(nil)
                            }
                        }
                        .frame(minWidth: collapsed ? TopBarView.collapsedTopBarHalfWidth : nil, maxWidth: .infinity, alignment: .trailing)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(x: scaleX, y: scaleY, anchor: isLeft ? .topTrailing : .topLeading)
        .transition(NotchView.defaultTransition(anchor: isLeft ? .trailing : .leading, delay: 0.075))
        .allowsHitTesting(liveActivitiesSettings.interactive || notchNook.mode == .nook || notchNook.mode == .tray)
    }
}
