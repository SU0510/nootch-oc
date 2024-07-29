//
//  interpolatorBuilder.swift
//  NotchNook
//
//  Created by Igor Marcossi on 19/05/24.
//

import Foundation
import SwiftUI

typealias InterpolatorBuilder = (_ range2: [CGFloat], _ extrapolate: Bool, _ curve: UnitCurve) -> CGFloat

func interpolatorBuilder(_ range1: [CGFloat], value: CGFloat) -> InterpolatorBuilder {
    func interpolate(_ range2: [CGFloat], _ extrapolate: Bool, _ curve: UnitCurve = .linear) -> CGFloat {
        let min1 = range1[0]
        let max1 = range1[1]
        let min2 = range2[0]
        let max2 = range2[1]
        
        // Normalize the input value to 0-1 range
        let normalizedValue = (value - min1) / (max1 - min1)
        
        if extrapolate {
            if value < min1 {
                let extrapolation = -normalizedValue
                let interpolationFactor = max(0, 1 + extrapolation / 4)
                return interpolationFactor * (min2 - max2) + max2
            } else if value > max1 {
                let extrapolation = normalizedValue - 1
                let interpolationFactor = max(0, 1 - extrapolation / 4)
                return interpolationFactor * (max2 - min2) + min2
            }
        }
        
        // Apply the curve to the normalized value
        let curvedValue = curve.value(at: normalizedValue)
        
        // Interpolate the curved value to the output range
        let interpolatedValue = curvedValue * (max2 - min2) + min2
        
        return max(min(min2, max2), min(max(min2, max2), interpolatedValue))
    }
    return interpolate
}
