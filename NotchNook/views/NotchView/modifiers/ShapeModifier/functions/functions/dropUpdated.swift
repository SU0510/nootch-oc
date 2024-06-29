//
//  dropUpdated.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView.ShapeModifier {
    func dropUpdated(info: NSDraggingInfo, mousePos: CGPoint) {
        if state.trialOver { return }
        state.droppingCoords = mousePos
    }
}
