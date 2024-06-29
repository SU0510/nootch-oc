//
//  dropExited.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

extension NotchView.ShapeModifier {
    func dropExited(info: NSDraggingInfo) {
        finishDragging(close: tray.files.count == 0)
    }
}
