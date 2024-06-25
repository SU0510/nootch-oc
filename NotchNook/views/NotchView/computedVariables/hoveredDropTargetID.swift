//
//  hoveredDropTargetID.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    var hoveredDropTargetID: String? {
        if let droppingCoords,
           let found = targetsCoords.first(where: { $1.contains(droppingCoords) }) {
            return found.key
        }
        return nil
    }
}
