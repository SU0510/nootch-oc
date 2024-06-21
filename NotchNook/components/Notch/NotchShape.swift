//
//  notchShape.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShape: Shape {
    static let defaultNotchWidth: CGFloat = getNotchDefaultWidth()
    static let defaultScreenWidth: CGFloat = getScreenDefaultWidth()
    static func getNotchWidthForScreenWidth(_ screenW: CGFloat) -> CGFloat {
        return (NotchShape.defaultNotchWidth * screenW) / NotchShape.defaultScreenWidth
    }
    
    var notchHeight: CGFloat
    var minWidth: CGFloat = NotchShape.defaultNotchWidth

    func path(in rect: CGRect) -> Path {
        var notchRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([notchHeight, notchHeight + 100], value: rect.height)
            return widthInterpolator([notchHeight < 14 ? notchHeight * 0.75 : 11, 40], true)
        }
        
        var decorationsRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([minWidth, minWidth + 300], value: rect.width)
            return widthInterpolator([max(0, min(5, notchHeight - notchRadius)), 24], true)
        }
        
        
        let decorationSize = decorationsRadius * 2
        
        let mainShapePath = UnevenRoundedRectangle(
            cornerRadii: .init(bottomLeading: notchRadius, bottomTrailing: notchRadius),
            style: .continuous
        ).size(width: rect.width, height: rect.height + 1).path(in: rect)
        
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
