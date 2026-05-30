//
//  openNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.EnvironmentsModifier {
    func openNotch(in newMode: NotchNookState.NotchMode = .nook) {
        withAnimation(NotchView.animation) {
            state.hovering = true
            state.cancelPan = true
            if notchNook.hidden { notchNook.hidden = false } else {
                notchNook.mode = newMode
            }
        } completion: {
            state.cancelPan = false
        }
    }
}
