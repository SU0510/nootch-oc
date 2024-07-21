//
//  IndicatorView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/07/24.
//

import SwiftUI

struct IndicatorView: View {
    var indicator: Indicator
    @Environment(\.notchSize) private var notchSize
    var body: some View {
        Group {
            switch indicator.kind {
                case .brightness: BrightnessIndicatorView(indicator: indicator)
                case .volume: BrightnessIndicatorView(indicator: indicator)
            }
        }
        .frame(
            width: (notchSize.width == 0 ? 182 : notchSize.width) + (TopBarView.liveActionWidth * 2) + (NotchView.paddingWhileHovering * 2),
            alignment: .bottomLeading
        )
    }
}
