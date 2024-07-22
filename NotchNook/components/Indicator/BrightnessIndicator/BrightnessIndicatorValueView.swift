//
//  BrightnessIndicatorValueView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 21/07/24.
//

import SwiftUI

struct BrightnessIndicatorValueView: View, Equatable {
    static func == (lhs: BrightnessIndicatorValueView, rhs: BrightnessIndicatorValueView) -> Bool {
        lhs.brightnessValue == rhs.brightnessValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.glowColor == rhs.glowColor
    }
    
    let brightnessValue: Double
    let overflowAmount: Double
    let glowColor: Color
    
    private var glowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,1.0], value: brightnessValue) }
    private var overflowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,15.0], value: min(15, overflowAmount)) }
    
    private var textGradientColor1: Color {
        Color(
            red: glowInterpolator([0.5529, 0.8549], false, .easeInQuint),
            green: glowInterpolator([0.7725, 0.9843], false, .easeInQuint),
            blue: overflowInterpolator([1, 0.75], false, .linear)
        )
        .opacity(glowInterpolator([0.25, 0.85], false, .easeInQuint))
    }
    
    private var textGradientColor2: Color {
        Color(red: 0.5529, green: 0.7725, blue: overflowInterpolator([1.0, 0.5], false, .linear))
            .opacity(glowInterpolator([0.25, 0.85], false, .easeInQuint))
    }
    
    private var textGradientColor3: Color {
        Color(red: 0.5529, green: 0.7725, blue: overflowInterpolator([1.0, 0.25], false, .linear))
            .opacity(glowInterpolator([0.25, 0.15], false, .easeInQuint))
    }
    
    var body: some View {
        Text("\(Int(brightnessValue * 100))%")
            .contentTransition(.identity)
        .geometryGroup()
        .offset(x: brightnessValue == 1.0 ? 0 : 12)
        .blur(radius: overflowInterpolator([0, 0.5], false, .linear))
        .foregroundStyle(EllipticalGradient(gradient: Gradient(colors: [textGradientColor3, textGradientColor2, textGradientColor1]), center: .init(x: brightnessValue == 1.0 ? 0.5 :0.25, y: 1), startRadiusFraction: 1, endRadiusFraction: 0.33))
        .font(.system(size: 12, weight: .semibold))
        .zIndex(2)
    }
}
