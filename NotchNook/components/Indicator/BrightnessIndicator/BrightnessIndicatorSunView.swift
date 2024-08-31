//
//  BrightnessIndicatorSunView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/07/24.
//

import SwiftUI

struct BrightnessIndicatorSunView: View, Equatable {
    static func == (lhs: BrightnessIndicatorSunView, rhs: BrightnessIndicatorSunView) -> Bool {
        lhs.brightnessValue == rhs.brightnessValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.glowColor == rhs.glowColor
    }
    
    let brightnessValue: Double
    let overflowAmount: Double
    let glowColor: Color
    
    @State private var appeared = false
    private var glowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,1.0], value: brightnessValue) }
    private var overflowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,15.0], value: min(15, overflowAmount)) }
    
    var body: some View {
        let one = glowInterpolator([0, 1], false, .linear)
        let o5 = glowInterpolator([0, 0.5], false, .linear)
        let o6 = glowInterpolator([0, 0.6], false, .linear)
        let raysLength = overflowInterpolator([glowInterpolator([0, 1], false, .linear), 1.25], false, .linear)
        let opacityInterp = glowInterpolator([0.5, 1], false, .linear)
        SunShape(raysLength: raysLength)
            .stroke(
                .nonShockingWhite.opacity(opacityInterp)
                .shadow(.drop(color: glowColor.opacity(o5), radius: 48))
                .shadow(.drop(color: glowColor.opacity(one), radius: 32))
                .shadow(.drop(color: glowColor.opacity(o5), radius: 24))
                .shadow(.drop(color: glowColor.opacity(o6), radius: 16))
                .shadow(.drop(color: glowColor.opacity(o6), radius: 8))
                .shadow(.drop(color: glowColor.opacity(one), radius: 6))
                .shadow(.drop(color: glowColor.opacity(one), radius: 3))
                .shadow(.drop(color: glowColor.opacity(one), radius: 1)),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
            )
            .frame(25)
            .blur(radius: overflowInterpolator([o5, 0.75], false, .linear))
            .scaleEffect(appeared ? overflowInterpolator([1, 1.1], false, .linear) : 0.75, anchor: .init(x: 0.25, y: 0.25))
            .rotationEffect(.degrees(appeared ? 0 : -25))
            .offset(y: appeared ? 6 : 0)
            .onAppear { withAnimation(.smooth(extraBounce: 0.3).delay(0.15)) { appeared = true } }
    }
}

