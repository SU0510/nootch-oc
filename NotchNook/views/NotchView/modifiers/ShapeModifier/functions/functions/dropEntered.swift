//
//  dropEntered.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView.ShapeModifier {
    func dropEntered(info: NSDraggingInfo) {
        if state.trialOver { return }
        withAnimation(NotchView.intenseAnimation) {
            notchNook.mode = .dragging
        }
        let actionsToShow = allPipelines.filter { action in
            return info.draggingPasteboard.types?.contains(action.allowedFileTypes) ?? false
        }
        DispatchQueue.main.async {
            withAnimation(NotchView.intenseAnimation) {
                state.availableActions = actionsToShow
            }
        }
    }
}
