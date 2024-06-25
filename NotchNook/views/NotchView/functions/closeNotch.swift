//
//  closeNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func closeNotch(vibrate doVibrate: Bool = false, unhover: Bool = false) {
        withAnimation(.smooth(duration: 0.4)) {
            self.cancelPan = true
            if unhover {  self.hovering = false }
            if doVibrate { vibrate() }
            if mode != .closed {
                NotchNook.shared.mode[screenID] = .closed
            }
            if unhover || mode != .closed {
                animatingBack = true
            }
        } completion: {
            animatingBack = false
            cancelPan = false
        }
    }
}
