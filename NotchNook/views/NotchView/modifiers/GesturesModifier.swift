//
//  GesturesModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI
import Defaults
import Setapp

extension NotchView {
    struct GesturesModifier: ViewModifier {
        var state: NotchViewModel
        var disableNotchNook: Bool
        
        @Environment(\.notchNook) internal var notchNook
        @Environment(\.isEditingText) internal var isEditingText
        @Environment(\.resignFirstResponder) internal var resignFirstResponder
        @Environment(\.openSettings) internal var openSettings
        @Environment(\.openNotch) internal var openNotch
        @Environment(\.makeKeyWindow) internal var makeKeyWindow
        @Environment(\.closeNotch) internal var closeNotch
        @Environment(\.tray) internal var tray
        @Environment(\.checkTrialOver) internal var checkTrialOver
        @Environment(\.nookSettings) private var nookSettings
        @Environment(\.generalSettings) private var generalSettings
        @Default(.license) internal var license
        
        func body(content: Content) -> some View {
            content
                .allowsHitTesting(!disableNotchNook)
                .onTapGesture {
                    resignFirstResponder()
                    if nookSettings.enabled && notchNook.mode == .closed && !state.showIntro { openNotch(.nook) }
                }
                .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: onLongPress)
                .onHover(perform: onHover)
                .contextMenu {
                    Button("Open Settings") { openSettings(nil) }
                    Button("Quit NotchNook") { NSApp.terminate(nil) }
                }
        }
        
        func onLongPress(_ pressing: Bool) {
            if state.hovering {
                withAnimation(NotchView.intenseAnimation) {
                    state.pressing = pressing
                }
            }
        }
        
        func onHover(_ hovering: Bool) {
            if license == nil || state.trialOver { checkTrialOver() }
            
            if hovering {
                if notchNook.mode == .closed {
                    #if SETAPP_BUILD
                    SetappManager.shared.reportUsageEvent(.userInteraction)
                    #endif

                    if !tray.files.isEmpty || generalSettings.alwaysOpenNotchOnHover {
                        openNotch(tray.files.isEmpty ? .nook : .tray)
                    } else {
                        withAnimation(.bouncy(duration: 0.4, extraBounce: 0.25)) {
                            state.hovering = true
                        }
                    }
                } else {
                    makeKeyWindow()
                }
            } else {
                if (generalSettings.preventUnhoverCloseWhenTyping && isEditingText) || notchNook.locked { return }
                closeNotch(false, true)
            }
        }
    }
}
