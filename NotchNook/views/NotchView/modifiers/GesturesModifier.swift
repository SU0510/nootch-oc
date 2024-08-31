//
//  GesturesModifier.swift
//  NotchNook
//
//  Created by Igor Marcossi on 29/06/24.
//

import SwiftUI
import Defaults
#if SETAPP_BUILD
import Setapp
#endif

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
        
//        @State private var isHovering = false
//        @State private var hoverCheckTimer: Timer?
        @State private var appTransitionTimer: Timer?

        func body(content: Content) -> some View {
            content
                .allowsHitTesting(!disableNotchNook)
                .onTapGesture {
                    resignFirstResponder()
                    if nookSettings.enabled && notchNook.mode == .closed && !state.showIntro { openNotch(.nook) }
                }
                .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 30, perform: {}, onPressingChanged: onLongPress)
                .onHover(perform: onHover)
//                .onHover { hovering in
//                    if hovering {
//                        isHovering = true
//                        onHover(true)
//                    } else {
//                        scheduleHoverCheck()
//                    }
//                }
                .contextMenu {
                    Button("Open Settings") { openSettings(nil) }
                    Button("Quit NotchNook") { NSApp.terminate(nil) }
                }
//                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willResignActiveNotification)) { _ in
//                    scheduleAppTransition()
//                }
//                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
//                    appTransitionTimer?.invalidate()
//                }
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
        
//        private func scheduleHoverCheck() {
//            hoverCheckTimer?.invalidate()
//            hoverCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
//                if !isMouseInsideNotch() {
//                    isHovering = false
//                    onHover(false)
//                }
//            }
//        }
        
//        private func scheduleAppTransition() {
//            appTransitionTimer?.invalidate()
//            appTransitionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
//                closeNotch(false, true)
//            }
//        }
        
//        private func isMouseInsideNotch() -> Bool {
//            guard let window = NSApp.windows.first(where: { $0.isVisible }),
//                  let screen = window.screen else { return false }
//            
//            let mouseLocation = NSEvent.mouseLocation
//            let y = screen.frame.height - NotchView.windowHeight
//            let notchFrame = CGRect(x: 0, y: y, width: screen.frame.width, height: NotchView.windowHeight)
//            
//            return notchFrame.contains(mouseLocation)
//        }
    }
}
