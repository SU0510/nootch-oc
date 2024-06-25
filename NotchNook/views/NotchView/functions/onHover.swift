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
                if !Shelf.shared.files.isEmpty || generalSettings.alwaysOpenNotchOnHover {
                    openNotch(in: Shelf.shared.files.isEmpty ? .nook : .shelf)
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
