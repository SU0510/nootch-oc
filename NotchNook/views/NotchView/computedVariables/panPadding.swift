//
//  panPadding.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    var panPadding: EdgeInsets {
        let topInterpolator = interpolatorBuilder([0, 150], value: abs(panRawPadding.top))
        let leadingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.leading)
        let trailingInterpolator = interpolatorBuilder([0, 150], value: panRawPadding.trailing)
        let bottomInterpolator = interpolatorBuilder([0, 200], value: panRawPadding.bottom)
        
        
        let leading = leadingInterpolator([0, Self.maxHPanDrag], true)
        let trailing = trailingInterpolator([0, Self.maxHPanDrag], true)
        let bottom = bottomInterpolator([0, Self.maxVPanDrag], true)
        
        let decrease = topInterpolator([0, 32], true)
        
        return .init(
            top: 0,
            leading: ((bottom * 0.5) + leading) - decrease,
            bottom: ((((leading + trailing) / 2) * 0.25) + bottom) - decrease,
            trailing: ((bottom * 0.5) + trailing) - decrease
        )
    }
}
