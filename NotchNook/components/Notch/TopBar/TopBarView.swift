//
//  TopBarView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import SwiftUI
import Defaults

struct TopBarView: View {
    static let animation: Animation = .bouncy(extraBounce: 0.075)
    static let height: CGFloat = 32
    static let liveActionWidth: CGFloat = 35
    var panGestureCounter: Int
    var scale: Double = 1
    var panPadding: EdgeInsets
    var hide: Bool
    @Environment(\.notchHeight) private var notchHeight
    @Environment(\.screenID) private var screenID
    @Environment(\.trialOver) private var trialOver
    @Environment(\.screenSize) private var screenSize
    @Default(.mediaLiveActivitySettings) private var mediaLiveActivitySettings
    @Default(.gestureControlSettings) private var gestureControlSettings
    @Default(.liveActivitiesSettings) private var liveActivitiesSettings
    @Default(.nookSettings) private var nookSettings
    @Default(.shelfSettings) private var shelfSettings
    var body: some View {
        let height = notchHeight > ((TopBarView.height / 3) * 2) ? notchHeight : TopBarView.height
        let mode = NotchNook.shared.mode[screenID]!
        let liveActvs = NotchNook.shared.activeLiveActivities
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                if !hide && !trialOver {
                    Group {
                        switch mode {
                            case .closed: LiveActivityView(side: .left, activeActivities: liveActvs).frame(width: Self.liveActionWidth)
                            case .dragging: EmptyView()
                            case .nook, .shelf: TopBarTabsView(totalWidth: mode == .nook ? nookSettings.size.width : shelfSettings.size.width)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale, anchor: .topTrailing)
                    .transition(NotchView.defaultTransition(anchor: .trailing, delay: 0.075))
                    .allowsHitTesting(liveActivitiesSettings.interactive || mode == .nook || mode == .shelf)
                }
                
                if (mode != .closed && !hide) || !liveActvs.isEmpty {
                    TopBarSpacerView(height: height)
                }
                
                if !hide && !trialOver {
                    Group {
                        switch mode {
                            case .closed: LiveActivityView(side: .right, activeActivities: liveActvs).frame(width: Self.liveActionWidth)
                            case .dragging: EmptyView()
                            case .nook, .shelf: HStack { if !nookSettings.enabledWidgets.contains(.media) { MiniPlayerView() } }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale, anchor: .topLeading)
                    .transition(NotchView.defaultTransition(anchor: .leading, delay: 0.075))
                    .allowsHitTesting(liveActivitiesSettings.interactive || mode == .nook || mode == .shelf)
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
                            case .dragging, .nook, .shelf: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale, anchor: .trailing)
                    .transition(.scaleAndBlur(anchor: .trailing))
                    
                    Spacer()
                        .frame(width: NotchShape.getNotchWidthForScreenWidth(screenSize.width)).fixedSize(horizontal: true, vertical: false)
                        .transition(.identity)
                    
                    Group {
                        switch mode {
                            case .closed:
                                ArrowForPanningView(x: !showArrows ? 0 : panPadding.trailing, right: true, inverted: gestureControlSettings.invertMediaGestures, counter: panGestureCounter)
                                    .frame(maxWidth: Self.liveActionWidth, maxHeight: .infinity, alignment: .trailing)
                            case .nook, .shelf, .dragging: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale, anchor: .leading)
                    .transition(.scaleAndBlur(anchor: .leading))
                }
            }
            .frame(height: (notchHeight == 0 && mode == .closed && liveActvs.isEmpty) || !hide ? nil : height)
            .fixedSize(horizontal: false, vertical: true)
            .zIndex(1)
        }
        if let quickPeeks = NotchNook.shared.quickPeeks {
            QuickPeeksView(quickPeeks: quickPeeks)
                .id(quickPeeks)
                .transition(.scaleAndBlur(anchor: .leading, blur: 15))
        }
    }
}
