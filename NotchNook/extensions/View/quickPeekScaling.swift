//
//  quickPeekScaling.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

extension View {
    func quickPeekScaling(scaling: Bool, anchor: UnitPoint = .topLeading, max: Double = 1.2) -> some View {
        self
            .scaleEffect(!scaling ? 1 : max, anchor: anchor)
    }
}
