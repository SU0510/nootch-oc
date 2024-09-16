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
        lhs.isHidden == rhs.isHidden
    }
    
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let maxHeight: CGFloat = 32
    static let liveActionWidth: CGFloat = 35
    static let collapsedTopBarHalfWidth: CGFloat = 88
    
    var panGestureCounter: Int
    var scaleX: Double = 1
    var scaleY: Double = 1
    var panPadding: EdgeInsets
    var isHidden: Bool
    
    private var liveActivities: Set<LiveActivity> {
        ActiveLiveActivitiesManager.shared.activeLiveActivities
    }
    @Environment(\.notchSize) private var notchSize
    @Environment(\.trialOver) private var trialOver
    @Environment(\.openSettings) private var openSettings
    @Environment(\.notchNook) private var notchNook
    @Environment(\.gestureControlSettings) private var gestureControlSettings
    @Environment(\.liveActivitiesSettings) private var liveActivitiesSettings
    @Environment(\.nookSettings) private var nookSettings
    @Environment(\.traySettings) private var traySettings
    @Environment(\.nookWidgetsWidth) private var nookWidgetsWidth
    
    var collapsed: Bool {
        let width = notchNook.mode == .nook ? nookWidgetsWidth : traySettings.size.width
        return width < .init(9)
    }

    var body: some View {
        let height = getHeight(notchSize.height)
        let mode = notchNook.mode
        let liveActivities = ActiveLiveActivitiesManager.shared.activeLiveActivities
        let shouldShowContent = !isHidden && !trialOver
        let shouldHide = (notchSize.height == 0 && mode == .closed && liveActivities.isEmpty) || isHidden
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if shouldShowContent {
                    contentView(isLeft: true)
                }
                
                if (mode != .closed && !isHidden) || !liveActivities.isEmpty {
                    TopBarSpacerView(height: height)
                }
                
                if shouldShowContent {
                    contentView(isLeft: false)
                }
            }
            .animation(.smooth(extraBounce: 0.25), value: liveActivities)
            .background {
                backgroundView(height: height)
            }
            .frame(height: shouldHide ? nil : height)
            .fixedSize(horizontal: false, vertical: true)
            .zIndex(1)
        }
        if let quickPeeks = notchNook.quickPeeks {
            QuickPeeksView(quickPeeks: quickPeeks)
                .id(quickPeeks)
                .transition(.scaleAndBlur(anchor: quickPeeks.first?.anchor ?? .topLeading, blur: 15))
        }
    }
    
    private func contentView(isLeft: Bool) -> some View {
        Group {
            switch notchNook.mode {
                case .closed:
                    LiveActivityView(side: isLeft ? .left : .right, activeActivities: liveActivities)
                        .frame(width: Self.liveActionWidth)
                case .dragging:
                    EmptyView()
                case .nook, .tray:
                    if isLeft {
                        TopBarTabsView(collapsed: collapsed)
                            .frame(width: collapsed ? Self.collapsedTopBarHalfWidth : nil, alignment: .leading)
                    } else {
                        HStack(spacing: 2) {
                            if !nookSettings.enabledWidgets.contains(.media) && !collapsed { MiniPlayerView() }
                            
                            CircleButton(icon: "gearshape.fill", iconSize: 13) {
                                openSettings(nil)
                            }
                        }
                        .frame(minWidth: collapsed ? Self.collapsedTopBarHalfWidth : nil, maxWidth: .infinity, alignment: .trailing)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(x: scaleX, y: scaleY, anchor: isLeft ? .topTrailing : .topLeading)
        .transition(NotchView.defaultTransition(anchor: isLeft ? .trailing : .leading, delay: 0.075))
        .allowsHitTesting(liveActivitiesSettings.interactive || notchNook.mode == .nook || notchNook.mode == .tray)
    }
    
    private func backgroundView(height: CGFloat) -> some View {
        HStack(spacing: 0) {
            let shouldShowArrows = panPadding.bottom < (NotchView.maxHPanDrag / 3) && gestureControlSettings.controlMedia
            backgroundContentView(isLeft: true, shouldShowArrows: shouldShowArrows)
            
            TopBarSpacerView(height: height)
            
            backgroundContentView(isLeft: false, shouldShowArrows: shouldShowArrows)
        }
    }
    
    private func backgroundContentView(isLeft: Bool, shouldShowArrows: Bool) -> some View {
        Group {
            switch notchNook.mode {
                case .closed:
                    ArrowForPanningView(
                        x: shouldShowArrows ? (isLeft ? -panPadding.leading : panPadding.trailing) : 0,
                        right: !isLeft,
                        inverted: gestureControlSettings.invertMediaGestures,
                        counter: panGestureCounter
                    )
                    .frame(maxWidth: Self.liveActionWidth, maxHeight: .infinity, alignment: isLeft ? .leading : .trailing)
                case .dragging, .nook, .tray:
                    EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .scaleEffect(x: scaleX, y: scaleY, anchor: isLeft ? .trailing : .leading)
        .transition(.scaleAndBlur(anchor: isLeft ? .trailing : .leading))
    }
    
    /// If notch height is bigger than 2/3 of minHeight, use it
    private func getHeight(_ notchHeight: CGFloat) -> CGFloat {
        if notchHeight == 0 {
            return liveActivitiesSettings.height
        } else {
            return notchHeight > (TopBarView.maxHeight * 0.66) ? notchHeight : TopBarView.maxHeight
        }
    }
}
