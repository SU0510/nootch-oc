//
//  VolumeIndicatorValueView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

struct VolumeIndicatorValueView: View, Equatable {
    static func == (lhs: VolumeIndicatorValueView, rhs: VolumeIndicatorValueView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let overflowAmount: Double
    let baseColor: Color
    
    private var volumeInterpolator: InterpolatorBuilder { interpolatorBuilder([0.0, 1.0], value: volumeValue) }
    
    var body: some View {
        IndicatorValueView(value: volumeValue)
            .foregroundColor(baseColor)
            .font(.system(size: 12, weight: .semibold))
            .zIndex(2)
    }
}
