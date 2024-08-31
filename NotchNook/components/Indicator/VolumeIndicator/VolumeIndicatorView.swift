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
    var disableColors: Bool = false
    
    @State private var overflowAmount: Double = 0
    
    private var rippleInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: overflowAmount) }
    
    private var baseColor: Color { .nonShockingWhite }
    
    var body: some View {
        VStack(alignment: .leading, spacing: -2) {
            VolumeIndicatorSpeakerView(volumeValue: indicator.value, overflowAmount: overflowAmount, baseColor: baseColor)
            
            VolumeIndicatorBarWrapperView(volumeValue: indicator.value, overflowAmount: overflowAmount, baseColor: baseColor, disableColors: disableColors)
        }
        .animation(.smooth, value: indicator.value)
        .padding(EdgeInsets(top: 18, leading: 10, bottom: 15, trailing: 10))
        .onChange(of: [indicator.id.uuidString, "\(indicator.value)"]) { oldValue, newValue in
            if oldValue[0] != newValue[0] && oldValue[1] == newValue[1] {
                withAnimation(.easeInOut(duration: 0.5)) {
                    overflowAmount = 1.0
                }
            }
        }
        .onChangeDebounced(of: indicator.id, delay: 0.5) { _ in
            if overflowAmount != 0 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    overflowAmount = 0
                }
            }
        }
        .drawingGroup()
    }
}
