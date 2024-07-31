//
//  VolumeIndicatorBarWrapperView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/07/24.
//

import SwiftUI

struct VolumeIndicatorBarWrapperView: View, Equatable {
    static func == (lhs: VolumeIndicatorBarWrapperView, rhs: VolumeIndicatorBarWrapperView) -> Bool {
        lhs.volumeValue == rhs.volumeValue &&
        lhs.overflowAmount == rhs.overflowAmount &&
        lhs.baseColor == rhs.baseColor
    }
    
    let volumeValue: Double
    let overflowAmount: Double
    let baseColor: Color
    var disableColors: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 4) {
                VolumeIndicatorValueView(volumeValue: volumeValue, overflowAmount: overflowAmount, baseColor: baseColor)
                    .frame(width: min(geo.size.width - 2, max(52, geo.size.width * volumeValue + 12)), alignment: .trailing)
                VolumeIndicatorBarView(
                    totalWidth: geo.size.width, 
                    volumeValue: volumeValue,
                    overflowAmount: overflowAmount,
                    baseColor: baseColor,
                    disableColors: disableColors
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 31, alignment: .leading)
        .padding(.horizontal, 6)
    }
}



