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
    
    @State private var appeared = false
    @State private var overflowAmount: Double = 0
    
    private let minTrailingHeight: Double = 2
    private let maxTrailingHeight: Double = 4
    
    private var glowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,1.0], value: indicator.value) }
    private var overflowInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0,10.0], value: overflowAmount) }
    
    private var glowColor: Color { Color(red: 0.56, green: 0.8, blue: overflowInterpolator([1, 0.75], false, .linear)) }
    
    private var textGradientColor1: Color {
        Color(
            red: glowInterpolator([0.5529, 0.8549], false, .easeInQuint),
            green: glowInterpolator([0.7725, 0.9843], false, .easeInQuint),
            blue: overflowInterpolator([0.75, 1], false, .linear)
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
    
    private var brightnessText: String { "\(Int(indicator.value * 100))%" }
    
    private var textView: some View { Text(brightnessText).blendMode(.overlay) }
    
    private var commetShape: some Shape {
        return HorizontalCometShape(leadingScale: minTrailingHeight / maxTrailingHeight, trailingScale: glowInterpolator([minTrailingHeight / maxTrailingHeight, overflowInterpolator([1, 1.25], false, .linear)], true, .linear))
    }

    private func commetShapeBlur(opacity: Double, blur: Double) -> some View {
        commetShape.fill(glowColor.opacity(opacity)).blur(radius: blur)
    }
    
    private func sunBlurView(opacity: Double, blur: Double) -> some View {
        let raysLength = overflowInterpolator([glowInterpolator([0, 1], false, .linear), 1.25], false, .linear)
        return SunShape(raysLength: raysLength)
            .stroke(glowColor.opacity(opacity), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .frame(width: 20, height: 20)
            .blur(radius: blur)
    }
    
    var body: some View {
        let one = glowInterpolator([0, 1], false, .linear)
        let o5 = glowInterpolator([0, 0.5], false, .linear)
        let o6 = glowInterpolator([0, 0.6], false, .linear)
        let opacityInterp = glowInterpolator([0.1, 1], false, .linear)
        VStack(alignment: .leading, spacing: 0) {
            let raysLength = overflowInterpolator([glowInterpolator([0, 1], false, .linear), 1.25], false, .linear)
            SunShape(raysLength: raysLength)
                .stroke(
                    .white.opacity(opacityInterp)
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
            
            
            GeometryReader { geo in
                VStack(alignment: .trailing, spacing: 4) {
                    Text(brightnessText)
                        .foregroundStyle(EllipticalGradient(gradient: Gradient(colors: [textGradientColor3, textGradientColor2, textGradientColor1]), center: .init(x: indicator.value == 1.0 ? 0.5 :0.25, y: 1), startRadiusFraction: 1, endRadiusFraction: 0.33))
                        .blur(radius: overflowInterpolator([0, 0.5], false, .linear))
                        .offset(x: indicator.value == 1.0 ? 0 : 12)
                        .geometryGroup()
                        .contentTransition(.numericText())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .zIndex(2)
                    
                    commetShape
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
                .frame(width: geo.size.width * indicator.value, alignment: .trailing)
            }
            .frame(maxWidth: .infinity, maxHeight: 23, alignment: .leading)
            .padding(.horizontal, 6)
        }
        .brightness(overflowInterpolator([0, 0.5], true, .linear))
        .onChange(of: [indicator.id.uuidString, "\(indicator.value)"]) { oldValue, newValue in
            if oldValue[0] != newValue[0] && oldValue[1] == newValue[1] {
                withAnimation(.smooth) {
                    overflowAmount += 1
                }
            }
        }
        .onChangeDebounced(of: overflowAmount, delay: 0.25) { _ in
            withAnimation(.snappy) {
                overflowAmount = 0
            }
        }
        .animation(.smooth, value: indicator.value)
        .background { Color.black.padding(.horizontal, -8) }
        .compositingGroup()
        .padding(EdgeInsets(top: 16, leading: 10, bottom: 20, trailing: 10))
    }
}

