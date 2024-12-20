//
//  GIFScalingQuality.swift
//  NotchNook
//
//  Created by Lori Montenegro on 19/12/24.
//

import AppKit

enum GIFScalingQuality: String, CaseIterable, Codable {
    case pixelPerfect = "Pixel-perfect"
    case interpolated = "Interpolated"
    
    var description: String {
        switch self {
            case .pixelPerfect:
                return "Good for pixel art GIFs"
            case .interpolated:
                return "Good for all other types of art"
        }
    }
    
    var scalingMode: NSImageScaling {
        switch self {
            case .pixelPerfect:
                return .scaleAxesIndependently
            case .interpolated:
                return .scaleProportionallyUpOrDown
        }
    }
    
    var interpolation: NSImageInterpolation {
        switch self {
            case .pixelPerfect:
                return .none
            case .interpolated:
                return .high
        }
    }
}
