//
//  notchShape.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShape: Shape {
    static let defaultNotchWidth: CGFloat = 184
    static let defaultEstimatedMaxExceedingWidth: CGFloat = 300
    static let defaultEstimatedMaxExceedingHeight: CGFloat = 100184
    
    var minHeight: CGFloat
    var minWidth: CGFloat = NotchShape.defaultNotchWidth
    var estimatedMaxExceedingWidth: CGFloat = NotchShape.defaultEstimatedMaxExceedingWidth
    var estimatedMaxExceedingHeight: CGFloat = NotchShape.defaultEstimatedMaxExceedingHeight

    func path(in rect: CGRect) -> Path {
        var decorationsRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([minWidth, minWidth + 300], value: rect.width)
            return widthInterpolator([5, 24], true)
        }
        
        var notchRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([minHeight, minHeight + 100], value: rect.height)
            return widthInterpolator([11, 40], true)
        }
        
        let decorationSize = decorationsRadius * 2
        
        let mainShapePath = UnevenRoundedRectangle(
            cornerRadii: .init(bottomLeading: notchRadius, bottomTrailing: notchRadius),
            style: .continuous
        ).path(in: rect)
        
        let leftDecorationPath = Rectangle()
            .path(in: CGRect(x: -decorationSize, y: 0, width: decorationSize, height: decorationSize))
            .subtracting(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topTrailing: decorationsRadius),
                    style: .continuous
                ).path(in: CGRect(x: -decorationSize, y: 0, width: decorationSize, height: decorationSize))
            )
        
        let rightDecorationPath = Rectangle()
            .path(in: CGRect(x: rect.maxX, y: 0, width: decorationSize, height: decorationSize))
            .subtracting(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: decorationsRadius),
                    style: .continuous
                ).path(in: CGRect(x: rect.maxX, y: 0, width: decorationSize, height: decorationSize))
            )
        
        var combinedPath = mainShapePath
        combinedPath.addPath(leftDecorationPath)
        combinedPath.addPath(rightDecorationPath)
        
        return combinedPath
    }
}
