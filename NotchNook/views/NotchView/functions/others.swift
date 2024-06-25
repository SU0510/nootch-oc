//
//  others.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {    
    func finishDragging(close: Bool) {
        if droppingCoords != nil { droppingCoords = nil }
        
        withAnimation(.smooth(duration: 0.4)) {
            if !availableActions.isEmpty {
                availableActions.removeAll()
            }
            if mode != .closed {
                NotchNook.shared.mode[screenID] = close ? .closed : .shelf
            }
        }
    }
    
    func dropEntered(info: NSDraggingInfo) {
        if trialOver { return }
        withAnimation(NotchView.intenseAnimation) {
            NotchNook.shared.mode[screenID] = .dragging
        }
        let actionsToShow = allDropActions.filter { action in
            return info.draggingPasteboard.types?.contains(action.allowedFileTypes) ?? false
        }
        DispatchQueue.main.async {
            withAnimation(NotchView.intenseAnimation) {
                availableActions = actionsToShow
            }
        }
    }
    
    func dropUpdated(info: NSDraggingInfo, mousePos: CGPoint) {
        if trialOver { return }
        droppingCoords = mousePos
    }
    
    func dropExited(info: NSDraggingInfo) {
        finishDragging(close: Shelf.shared.files.count == 0)
    }
}
