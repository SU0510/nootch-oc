//
//  BrightnessIndicatorCometView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/07/24.
//

import SwiftUI

struct BrightnessIndicatorCometView: View, Equatable {
    static func == (lhs: BrightnessIndicatorCometView, rhs: BrightnessIndicatorCometView) -> Bool {
        lhs.brightnessValue == rhs.brightnessValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.glowColor == rhs.glowColor
    }
    
    let brightnessValue: Double
    let overflowAmount: Double
    let glowColor: Color
    
    private let minTrailingHeight: Double = 2
    private let maxTrailingHeight: Double = 4
    
    private var glowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,1.0], value: brightnessValue) }
    private var overflowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,15.0], value: min(15, overflowAmount)) }
    
    private var mainGradient: LinearGradient {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.62, green: 0.83, blue: overflowInterpolator([1.0, 0.5], false, .linear)), location: 0.00),
                Gradient.Stop(color: Color(red: 0.84, green: 0.93, blue: overflowInterpolator([1.0, 0.85], false, .linear)), location: 0.925),
                Gradient.Stop(color: Color(red: 1.0, green: 1.0, blue: 1.0), location: 1.00),
            ],
            startPoint: UnitPoint(x: 0, y: 0.5),
            endPoint: UnitPoint(x: 1, y: 0.5)
        )
    }
    
    var body: some View {
        let one = glowInterpolator([0, 1], false, .linear)
        let o5 = glowInterpolator([0, 0.5], false, .linear)
        let o6 = glowInterpolator([0, 0.6], false, .linear)
        HorizontalCometShape(leadingScale: minTrailingHeight / maxTrailingHeight, trailingScale: glowInterpolator([minTrailingHeight / maxTrailingHeight, overflowInterpolator([1, 1.35], false, .linear)], true, .linear))
            .fill(
                mainGradient.opacity(one)
                    .shadow(.drop(color: glowColor.opacity(o5), radius: 56))
                    .shadow(.drop(color: glowColor.opacity(one), radius: 56))
                    .shadow(.drop(color: glowColor.opacity(o5), radius: 32))
                    .shadow(.drop(color: glowColor.opacity(o6), radius: 24))
                    .shadow(.drop(color: glowColor.opacity(o6), radius: 16))
                    .shadow(.drop(color: glowColor.opacity(one), radius: 12))
                    .shadow(.drop(color: glowColor.opacity(one), radius: 4))
                    .shadow(.drop(color: glowColor.opacity(one), radius: 1))
            )
            .frame(height: maxTrailingHeight)
            .blur(radius: overflowInterpolator([o5, 1.5], false, .linear))
            .zIndex(1)
    }
}
