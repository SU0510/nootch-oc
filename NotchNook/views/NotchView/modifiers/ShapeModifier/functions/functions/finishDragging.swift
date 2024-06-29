//
//  finishDragging.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView.ShapeModifier {
    func finishDragging(close: Bool) {
        if state.droppingCoords != nil { state.droppingCoords = nil }
        
        withAnimation(.smooth(duration: 0.4)) {
            if !state.availableActions.isEmpty {
                state.availableActions.removeAll()
            }
            if notchNook.mode != .closed {
                notchNook.mode = close ? .closed : .tray
            }
        }
    }
}
