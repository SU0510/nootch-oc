//
//  openNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func openNotch(in newMode: NotchNook.NotchMode = .nook) {
        hideTimer?.invalidate()
        withAnimation(Self.animation) {
            hovering = true
            cancelPan = true
            if hide { hide = false } else {
                NotchNook.shared.mode[screenID] = newMode
            }
        } completion: {
            cancelPan = false
        }
    }
}
