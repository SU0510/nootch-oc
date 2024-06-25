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
            panRawPadding = .zero
            cancelPan = true
            if prev { panGestureCounter -= 1 } else { panGestureCounter += 1 }
        }
    }
}
