//
//  BrightnessIndicatorBarWrapperView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 26/07/24.
//

import SwiftUI

struct BrightnessIndicatorBarWrapperView: View, Equatable {
    static func == (lhs: BrightnessIndicatorBarWrapperView, rhs: BrightnessIndicatorBarWrapperView) -> Bool {
        lhs.brightnessValue == rhs.brightnessValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.glowColor == rhs.glowColor
    }
    
    let brightnessValue: Double
    let overflowAmount: Double
    let glowColor: Color
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 4) {
                BrightnessIndicatorValueView(brightnessValue: brightnessValue, overflowAmount: overflowAmount, glowColor: glowColor)
                    .frame(width: min(geo.size.width, max(52, geo.size.width * brightnessValue + 16)), alignment: .trailing)
                BrightnessIndicatorCometView(brightnessValue: brightnessValue, overflowAmount: overflowAmount, glowColor: glowColor)
                    .frame(width: geo.size.width * brightnessValue, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 23, alignment: .leading)
        .padding(.horizontal, 6)
    }
}
