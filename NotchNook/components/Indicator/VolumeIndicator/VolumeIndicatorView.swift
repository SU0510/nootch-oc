//
//  VolumeIndicatorView.swift
//  NotchNook
//
//  Created by Ethan Bills on 7/24/24.
//

import SwiftUI

struct VolumeIndicatorView: View, Equatable {
    static func == (lhs: VolumeIndicatorView, rhs: VolumeIndicatorView) -> Bool {
        lhs.indicator == rhs.indicator
    }
    
    var indicator: Indicator
    
    @State private var rippleEffect: Double = 0
    
    private var rippleInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: rippleEffect) }
    
    private var baseColor: Color { Color(red: 0.2, green: 0.6, blue: 1.0) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VolumeIndicatorSpeakerView(volumeValue: indicator.value, rippleEffect: rippleEffect, baseColor: baseColor)
            
            VolumeIndicatorBarWrapperView(volumeValue: indicator.value, rippleEffect: rippleEffect, baseColor: baseColor)
        }
        .animation(.smooth, value: indicator.value)
        .padding(EdgeInsets(top: 16, leading: 10, bottom: 20, trailing: 10))
        .onChange(of: [indicator.id.uuidString, "\(indicator.value)"]) { oldValue, newValue in
            if oldValue[0] != newValue[0] && oldValue[1] == newValue[1] {
                withAnimation(.easeInOut(duration: 0.5)) {
                    rippleEffect = 1.0
                }
            }
        }
        .onChangeDebounced(of: indicator.id, delay: 0.5) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                rippleEffect = 0
            }
        }
    }
}

struct VolumeIndicatorBarWrapperView: View, Equatable {
    static func == (lhs: VolumeIndicatorBarWrapperView, rhs: VolumeIndicatorBarWrapperView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.rippleEffect == rhs.rippleEffect &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let rippleEffect: Double
    let baseColor: Color
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .trailing, spacing: 4) {
                VolumeIndicatorValueView(volumeValue: volumeValue, rippleEffect: rippleEffect, baseColor: baseColor)
                VolumeIndicatorBarView(volumeValue: volumeValue, rippleEffect: rippleEffect, baseColor: baseColor)
            }
            .frame(width: geo.size.width * volumeValue, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: 23, alignment: .leading)
        .padding(.horizontal, 6)
    }
}

struct VolumeIndicatorSpeakerView: View, Equatable {
    static func == (lhs: VolumeIndicatorSpeakerView, rhs: VolumeIndicatorSpeakerView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.rippleEffect == rhs.rippleEffect &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let rippleEffect: Double
    let baseColor: Color
    
    @State private var appeared = false
    private var volumeInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: volumeValue) }
    private var rippleInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: rippleEffect) }
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(baseColor.opacity(0.3), lineWidth: 1)
                    .scaleEffect(rippleInterpolator([1, 1.5 + Double(i) * 0.2], false, .easeOut))
                    .opacity(rippleInterpolator([0, 1 - Double(i) * 0.3], true, .easeOut))
            }
            
            Image(systemName: "speaker.wave.3.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(baseColor)
                .frame(width: 25, height: 25)
        }
        .frame(width: 40, height: 40)
        .scaleEffect(appeared ? volumeInterpolator([0.9, 1.1], false, .circularEaseInOut) : 0.75)
        .rotationEffect(.degrees(appeared ? 0 : -25))
        .offset(y: appeared ? 6 : 0)
        .onAppear { withAnimation(.smooth(extraBounce: 0.3).delay(0.15)) { appeared = true } }
    }
}

struct VolumeIndicatorValueView: View, Equatable {
    static func == (lhs: VolumeIndicatorValueView, rhs: VolumeIndicatorValueView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.rippleEffect == rhs.rippleEffect &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let rippleEffect: Double
    let baseColor: Color
    
    private var volumeInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: volumeValue) }
    
    var body: some View {
        Text("\(Int(volumeValue * 100))%")
            .contentTransition(.identity)
            .geometryGroup()
            .offset(x: volumeValue == 1.0 ? 0 : 12)
            .foregroundColor(baseColor)
            .font(.system(size: 12, weight: .semibold))
            .zIndex(2)
    }
}

struct VolumeIndicatorBarView: View, Equatable {
    static func == (lhs: VolumeIndicatorBarView, rhs: VolumeIndicatorBarView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.rippleEffect == rhs.rippleEffect
    }
    
    let volumeValue: Double
    let rippleEffect: Double
    let baseColor: Color
    
    private var volumeInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: volumeValue) }
    private var rippleInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: rippleEffect) }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                backgroundBar
                filledBar(in: geometry)
                volumeBars(in: geometry)
            }
            .overlay(rippleEffect(in: geometry))
        }
        .frame(height: 4)
        .cornerRadius(2)
    }
    
    private var backgroundBar: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
    }
    
    private func filledBar(in geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: geometry.size.width * CGFloat(volumeValue))
    }
    
    private func volumeBars(in geometry: GeometryProxy) -> some View {
        ForEach(0..<Int(volumeValue * 10), id: \.self) { index in
            volumeBar(at: index, in: geometry)
        }
    }
    
    private func volumeBar(at index: Int, in geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.white)
            .frame(width: 2, height: geometry.size.height * volumeInterpolator([0.5, 1.0], false, .circularEaseInOut))
            .offset(x: geometry.size.width * CGFloat(Double(index) / 10))
            .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.03), value: volumeValue)
    }
    
    private func rippleEffect(in geometry: GeometryProxy) -> some View {
        Rectangle()
            .stroke(Color.white.opacity(0.5), lineWidth: rippleInterpolator([0, 2], false, .easeOut))
            .cornerRadius(2)
            .scaleEffect(rippleInterpolator([1, 1.05], false, .easeOut))
            .opacity(rippleInterpolator([0, 1], true, .easeOut))
    }
}
