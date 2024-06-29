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
        @Default(.generalSettings) internal var generalSettings
        @Default(.intro) internal var intro
        @Default(.liveActivitiesSettings) internal var liveActivitiesSettings
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.closeNotch) internal var closeNotch
        @Environment(\.hideNotch) internal var hideNotch
        @Environment(\.openNotch) internal var openNotch
        @Environment(\.notchSize) internal var notchSize
        @Environment(\.tray) internal var tray
        @Namespace internal var ns
        
        var shouldRender: Bool {
            let showingLiveActvs = LiveActivitiesManager.shared.activeLiveActivities.filter {
                liveActivitiesSettings.enabledLiveActivities.contains($0)
            }
            return (
                notchNook.mode != .closed ||
                state.fineTuningNotchWidth ||
                (intro && state.showIntro) ||
                !showingLiveActvs.isEmpty ||
                generalSettings.demoMode ||
                notchSize.height == 0 ||
                state.hovering ||
                state.animatingBack
            )
        }
        
        func body(content: Content) -> some View {
            content
                .mask(alignment: .top) { notchShapeView(shadow: false, transparentHandle: false) }
                .contentShape(NotchShape(notchSize: notchSize))
                .background(alignment: .top) {
                    ZStack {
                        Color.hitBox
                        
                        let showFileDropView = notchNook.mode == .closed || notchNook.mode == .dragging
                        if showFileDropView {
                            FileDropView(dropEntered: dropEntered, dropUpdated: dropUpdated, performDrop: performDrop, dropExited: dropExited)
                        }
                        
                        notchShapeView()
                        
                        NotchGesturer(state: state)
                    }
                }
        }
    }
}

