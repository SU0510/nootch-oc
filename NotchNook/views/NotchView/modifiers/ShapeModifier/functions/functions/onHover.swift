//
//  onHover.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func onHover(_ hovering: Bool) {
        if license == nil || trialOver { checkTrialOver() }
        
        if hovering {
            // Make panel key on hover to prevent first-click absorption — clicks on a non-key .nonactivatingPanel are consumed by AppKit to activate the panel and never reach SwiftUI gestures.
            makeKeyWindow()
            if mode == .closed {
                if !tray.files.isEmpty || generalSettings.alwaysOpenNotchOnHover {
                    openNotch(in: tray.files.isEmpty ? .nook : .tray)
                } else {
                    withAnimation(.bouncy(duration: 0.4, extraBounce: 0.25)) {
                        self.hovering = true
                    }
                }
            } else {
                makeKeyWindow()
            }
        } else {
            closeNotch(unhover: true)
        }
    }
}
