//
//  notchShape.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShape: Shape {
    static let notchlessScreenNotchHeight: CGFloat = 8
    static let usualNotchHeight: CGFloat = 32
    static let defaultNotchWidth: CGFloat = 184
    static let defaultEstimatedMaxExceedingWidth: CGFloat = 400
    static let defaultEstimatedMaxExceedingHeight: CGFloat = 100
    
    var notchHeight: CGFloat
    var minWidth: CGFloat = NotchShape.defaultNotchWidth
    var estimatedMaxExceedingWidth: CGFloat = NotchShape.defaultEstimatedMaxExceedingWidth
    var estimatedMaxExceedingHeight: CGFloat = NotchShape.defaultEstimatedMaxExceedingHeight

    func path(in rect: CGRect) -> Path {
        var decorationsRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([minWidth, minWidth + 300], value: rect.width)
            return widthInterpolator([notchHeight < 5 ? notchHeight / 2 : 5, 24], true)
        }
        
        var notchRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([notchHeight, notchHeight + 100], value: rect.height)
            return widthInterpolator([notchHeight < 11 ? notchHeight / 2 : 11, 40], true)
        }
        
        let decorationSize = decorationsRadius * 2
        
        let mainShapePath = UnevenRoundedRectangle(
            cornerRadii: .init(bottomLeading: notchRadius, bottomTrailing: notchRadius),
            style: .continuous
        ).size(width: rect.width, height: rect.height).path(in: rect)
        
        let leftDecorationPath = Rectangle()
            .path(in: CGRect(x: -decorationSize, y: 0, width: decorationSize, height: decorationSize))
            .subtracting(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topTrailing: decorationsRadius),
                    style: .continuous
                ).path(in: CGRect(x: -decorationSize, y: 0, width: decorationSize, height: decorationSize))
            )
            .offsetBy(dx: 0, dy: 1)
        
        let rightDecorationPath = Rectangle()
            .path(in: CGRect(x: rect.maxX, y: 0, width: decorationSize, height: decorationSize))
            .subtracting(
                UnevenRoundedRectangle(
                    cornerRadii: .init(topLeading: decorationsRadius),
                    style: .continuous
                ).path(in: CGRect(x: rect.maxX, y: 0, width: decorationSize, height: decorationSize))
            )
            .offsetBy(dx: 0, dy: 1)
        
        var combinedPath = mainShapePath
        combinedPath.addPath(leftDecorationPath)
        combinedPath.addPath(rightDecorationPath)
        
        return combinedPath
    }
}
