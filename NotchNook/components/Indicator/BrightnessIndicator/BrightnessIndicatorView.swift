//
//  BrightnessIndicatorView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/07/24.
//

import SwiftUI

struct BrightnessIndicatorView: View, Equatable {
    static func == (lhs: BrightnessIndicatorView, rhs: BrightnessIndicatorView) -> Bool {
        lhs.indicator == rhs.indicator
    }
    
    var indicator: Indicator
    
    @State private var overflowAmount: Double = 0
    
    private var overflowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,15.0], value: min(15, overflowAmount)) }
    
    private var glowColor: Color { Color(red: 0.56, green: 0.8, blue: overflowInterpolator([1, 0.75], false, .linear)) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrightnessIndicatorSunView(brightnessValue: indicator.value, overflowAmount: overflowAmount, glowColor: glowColor)
            
            BrightnessIndicatorBarWrapperView(brightnessValue: indicator.value, overflowAmount: overflowAmount, glowColor: glowColor)
        }
        .brightness(overflowInterpolator([0, 0.5], true, .linear))
        .animation(.smooth, value: indicator.value)
        .padding(EdgeInsets(top: 16, leading: 10, bottom: 20, trailing: 10))
        .onChange(of: [indicator.id.uuidString, "\(indicator.value)"]) { oldValue, newValue in
            if oldValue[0] != newValue[0] && oldValue[1] == newValue[1] && overflowAmount < 15 {
                withAnimation(.smooth) {
                    overflowAmount += 1
                }
            }
        }
        .onChangeDebounced(of: indicator.id, delay: 0.35) { _ in
            if overflowAmount != 0 {
                withAnimation(.smooth) {
                    overflowAmount = 0
                }
            }
        }
        .drawingGroup()
    }
}

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
            VStack(alignment: .trailing, spacing: 4) {
                BrightnessIndicatorValueView(brightnessValue: brightnessValue, overflowAmount: overflowAmount, glowColor: glowColor)
                BrightnessIndicatorCometView(brightnessValue: brightnessValue, overflowAmount: overflowAmount, glowColor: glowColor)
            }
            .frame(width: geo.size.width * brightnessValue, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: 23, alignment: .leading)
        .padding(.horizontal, 6)
    }
}
