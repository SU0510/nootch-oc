//
//  ShapeModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 28/06/24.
//

import SwiftUI
import Defaults

extension NotchView {
    struct ShapeModifier: ViewModifier {
        var state: NotchViewModel
        
        @Default(.intro) internal var intro
        @Environment(\.generalSettings) internal var generalSettings
        @Environment(\.liveActivitiesSettings) internal var liveActivitiesSettings
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.closeNotch) internal var closeNotch
        @Environment(\.hideNotch) internal var hideNotch
        @Environment(\.openNotch) internal var openNotch
        @Environment(\.notchSize) internal var notchSize
        @Environment(\.tray) internal var tray
        @Namespace internal var ns
        
        var shouldRender: Bool {
            // activeLiveActivities already applies the enabledLiveActivities filter AND
            // correctly bypasses it for always-on activities like .timerExpired.
            // Re-filtering here would silently drop .timerExpired and prevent the notch
            // mask from opening the LA region on timer expiry.
            let showingLiveActvs = ActiveLiveActivitiesManager.shared.activeLiveActivities
            return (
                notchNook.indicator != nil ||
                notchNook.mode != .closed ||
                state.notchState == .fineTuningWidth ||
                state.notchState == .fineTuningHeight ||
                (intro && state.showIntro) ||
                !showingLiveActvs.isEmpty ||
                generalSettings.demoMode ||
                notchSize.height == 0 && !generalSettings.transparentHandle ||
                state.hovering ||
                state.animatingBack
            )
        }
        
        func body(content: Content) -> some View {
            content
                .mask(alignment: .top) { notchShapeView(shadow: false, transparentHandle: false) }
                .background { NotchGesturer(state: state) }
                .contentShape(NotchShape(notchSize: notchSize, isWidthFineTuning: state.notchState == .fineTuningWidth))
                .background(alignment: .top) {
                    ZStack {
                        Color.hitBox
                        
                        let showFileDropView = notchNook.mode == .closed || notchNook.mode == .dragging
                        if showFileDropView {
                            FileDropView(dropEntered: dropEntered, dropUpdated: dropUpdated, performDrop: performDrop, dropExited: dropExited)
                        }
                        
                        notchShapeView()
                    }
                    .animation(.bouncySmooth, value: liveActivitiesSettings)
                    .animation(.bouncySmooth, value: ActiveLiveActivitiesManager.shared.activeLiveActivities)
                }
        }
    }
}

