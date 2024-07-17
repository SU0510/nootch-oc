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
        if state.cancelPan { return }
        canBecomeKey.wrappedValue = false
        focusFrontmostWindow()
        if notchNook.mode != .closed {
            state.animatingBack = true
        }
        state.cancelPan = true
        if notchNook.mode != .closed {
            doAfter {
                withAnimation(.smooth(duration: 0.4)) {
                    state.animatingBack = false
                }
            }
        }
        withAnimation(.smooth(duration: 0.4)) {
            if unhover {  state.hovering = false }
            if doVibrate { vibrate() }
            if notchNook.mode != .closed {
                notchNook.mode = .closed
            }
        } completion: {
            state.cancelPan = false
        }
    }
}
