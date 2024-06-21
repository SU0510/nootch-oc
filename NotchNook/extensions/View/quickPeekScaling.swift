//
//  quickPeekScaling.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/06/24.
//

import SwiftUI

extension View {
    func quickPeekScaling(anchor: UnitPoint = .topLeading, max: Double = 1.2) -> some View {
        self
            .scaleEffect(NotchNook.shared.quickPeeks == nil ? 1 : max, anchor: anchor)
    }
}
