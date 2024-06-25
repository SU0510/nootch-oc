//
//  dropUpdated.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView {
    func dropUpdated(info: NSDraggingInfo, mousePos: CGPoint) {
        if trialOver { return }
        droppingCoords = mousePos
    }
}
