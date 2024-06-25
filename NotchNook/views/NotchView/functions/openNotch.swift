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
        withAnimation(Self.animation) {
            hovering = true
            cancelPan = true
            if notchNook.hidden { notchNook.hidden = false } else {
                notchNook.mode = newMode
            }
        } completion: {
            cancelPan = false
        }
    }
}
