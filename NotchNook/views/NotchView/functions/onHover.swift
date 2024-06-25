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
            if mode == .closed {
                if !Tray.shared.files.isEmpty || generalSettings.alwaysOpenNotchOnHover {
                    openNotch(in: Tray.shared.files.isEmpty ? .nook : .tray)
                } else {
                    withAnimation(.bouncy(duration: 0.4, extraBounce: 0.25)) {
                        self.hovering = true
                    }
                }
            }
        } else {
            closeNotch(unhover: true)
        }
    }
}
