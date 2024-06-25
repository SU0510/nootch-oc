//
//  finishDragging.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView {
    func finishDragging(close: Bool) {
        if droppingCoords != nil { droppingCoords = nil }
        
        withAnimation(.smooth(duration: 0.4)) {
            if !availableActions.isEmpty {
                availableActions.removeAll()
            }
            if mode != .closed {
                notchNook.mode = close ? .closed : .tray
            }
        }
    }
}
