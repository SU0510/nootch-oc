//
//  notchShape.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShape: Shape {
    static var notchWidthInInches: Double = 1.44313723
    static var maxNotchRadius: Double = 40
    static var maxDecorationRadius: Double = 24
    var notchSize: CGSize

    func path(in rect: CGRect) -> Path {
        var notchRadius: CGFloat {
            let heightInterpolator = interpolatorBuilder([notchSize.height, notchSize.height + 100], value: rect.height)
            return heightInterpolator([notchSize.height < 14 ? notchSize.height * 0.65 : 11, Self.maxNotchRadius], true)
        }
        
        var decorationsRadius: CGFloat {
            let widthInterpolator = interpolatorBuilder([notchSize.width, notchSize.width + 300], value: max(notchSize.width, rect.width))
            return widthInterpolator([max(0, min(5, rect.height - notchRadius)), Self.maxDecorationRadius], true)
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
