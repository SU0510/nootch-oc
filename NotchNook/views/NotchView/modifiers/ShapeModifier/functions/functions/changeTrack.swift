//
//  changeTrack.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    func changeTrack(prev: Bool) {
        withAnimation(.smooth) {
            vibrate()
            state.panRawPadding = .zero
            state.cancelPan = true
            if prev { state.panGestureCounter -= 1 } else { state.panGestureCounter += 1 }
        }
    }
}
