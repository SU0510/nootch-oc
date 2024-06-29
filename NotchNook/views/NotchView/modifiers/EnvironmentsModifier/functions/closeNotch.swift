//
//  closeNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.EnvironmentsModifier {
    func closeNotch(vibrate doVibrate: Bool = false, unhover: Bool = false) {
        canBecomeKey.wrappedValue = false
        focusFrontmostWindow()
        withAnimation(.smooth(duration: 0.4)) {
            state.cancelPan = true
            if unhover {  state.hovering = false }
            if doVibrate { vibrate() }
            if notchNook.mode != .closed {
                notchNook.mode = .closed
            }
            if unhover || notchNook.mode != .closed {
                state.animatingBack = true
            }
        } completion: {
            state.animatingBack = false
            state.cancelPan = false
        }
    }
}
