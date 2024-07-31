//
//  TopBarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import Defaults

struct TopBarView: View, Equatable {
    static func == (lhs: TopBarView, rhs: TopBarView) -> Bool {
        lhs.panGestureCounter == rhs.panGestureCounter &&
        lhs.scaleX == rhs.scaleX &&
        lhs.scaleY == rhs.scaleY &&
        lhs.panPadding == rhs.panPadding &&
        lhs.hide == rhs.hide
    }
    
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let minHeight: CGFloat = 32
    static let liveActionWidth: CGFloat = 35
    static func getHeight(_ notchHeight: CGFloat) -> CGFloat {
        notchHeight > (TopBarView.minHeight * 0.66) ? notchHeight : TopBarView.minHeight
    }
    
    var panGestureCounter: Int
    var scaleX: Double = 1
    var scaleY: Double = 1
    var panPadding: EdgeInsets
    var hide: Bool
    
    @Environment(\.notchSize) private var notchSize
    @Environment(\.trialOver) private var trialOver
    @Environment(\.openSettings) private var openSettings
    @Environment(\.notchNook) private var notchNook
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.nookSettings) private var nookSettings
    @Environment(\.traySettings) private var traySettings
    @Environment(\.nookWidgetsWidth) private var nookWidgetsWidth

    var body: some View {
        // If notch height is bigger than 2/3 of minHeight, use it
        let height = TopBarView.getHeight(notchSize.height)
        let mode = notchNook.mode
        let liveActvs = ActiveLiveActivitiesManager.shared.activeLiveActivities
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                if !hide && !trialOver {
                    Group {
                        switch mode {
                            case .closed: LiveActivityView(side: .left, activeActivities: liveActvs).frame(width: Self.liveActionWidth)
                            case .dragging: EmptyView()
                            case .nook, .tray: TopBarTabsView(totalWidth: mode == .nook ? nookWidgetsWidth : traySettings.size.width)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: scaleX, y: scaleY, anchor: .topTrailing)
                    .transition(NotchView.defaultTransition(anchor: .trailing, delay: 0.075))
                    .allowsHitTesting(liveActivitiesSettings.interactive || mode == .nook || mode == .tray)
                }
                
                if (mode != .closed && !hide) || !liveActvs.isEmpty {
                    TopBarSpacerView(height: height)
                }
                
                if !hide && !trialOver {
                    Group {
                        switch mode {
                            case .closed: LiveActivityView(side: .right, activeActivities: liveActvs).frame(width: Self.liveActionWidth)
                            case .dragging: EmptyView()
                            case .nook, .tray: 
                                HStack(spacing: 2) {
                                    if !nookSettings.enabledWidgets.contains(.media) { MiniPlayerView() }
                                    
                                    CircleButton(icon: "gearshape.fill", iconSize: 13) {
                                        openSettings(nil)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: scaleX, y: scaleY, anchor: .topLeading)
                    .transition(NotchView.defaultTransition(anchor: .leading, delay: 0.075))
                    .allowsHitTesting(liveActivitiesSettings.interactive || mode == .nook || mode == .tray)
                }
                
            }
            .animation(.smooth(extraBounce: 0.25), value: liveActvs)
            .background {
                HStack(spacing: 0) {
                    let showArrows = panPadding.bottom < (NotchView.maxHPanDrag / 3) && gestureControlSettings.controlMedia
                    Group {
                        switch mode {
                            case .closed:
                                ArrowForPanningView(x:  !showArrows ? 0 : -panPadding.leading, right: false, inverted: gestureControlSettings.invertMediaGestures, counter: panGestureCounter)
                                    .frame(maxWidth: Self.liveActionWidth, maxHeight: .infinity, alignment: .leading)
                            case .dragging, .nook, .tray: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: scaleX, y: scaleY, anchor: .trailing)
                    .transition(.scaleAndBlur(anchor: .trailing))
                    
                    TopBarSpacerView(height: height)
                    
                    Group {
                        switch mode {
                            case .closed:
                                ArrowForPanningView(x: !showArrows ? 0 : panPadding.trailing, right: true, inverted: gestureControlSettings.invertMediaGestures, counter: panGestureCounter)
                                    .frame(maxWidth: Self.liveActionWidth, maxHeight: .infinity, alignment: .trailing)
                            case .nook, .tray, .dragging: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: scaleX, y: scaleY, anchor: .leading)
                    .transition(.scaleAndBlur(anchor: .leading))
                }
            }
            .frame(height: (notchSize.height == 0 && mode == .closed && liveActvs.isEmpty) || hide ? nil : height)
            .fixedSize(horizontal: false, vertical: true)
            .zIndex(1)
        }
        if let quickPeeks = notchNook.quickPeeks {
            QuickPeeksView(quickPeeks: quickPeeks)
                .id(quickPeeks)
                .transition(.scaleAndBlur(anchor: .leading, blur: 15))
        }
    }
}
