//
//  hideNotch.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func hideNotch() {
        if hide { return }
        hideTimer?.invalidate()
        vibrate()
        withAnimation(.smooth) {
            hide = true
            hideTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                withAnimation(.smooth) { hide = false }
            }
        }
    }
}
