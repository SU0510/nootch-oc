//
//  notchShape.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShapeConfig {
    var height: CGFloat
    var width: CGFloat
    var outerRadius: CGFloat
    var innerRadius: CGFloat
    var shadow: Bool = false
}


func notchShape(extraWidth: CGFloat = 0, baseHeight: CGFloat, config: NotchShapeConfig) -> some Shape {
    let decorationSize = config.innerRadius * 2
    return UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: config.outerRadius, bottomTrailing: config.outerRadius), style: .continuous)
        .union(
            Rectangle().size(width: decorationSize, height: decorationSize)
                .subtracting(
                    UnevenRoundedRectangle(cornerRadii: .init(topTrailing: config.innerRadius), style: .continuous)
                        .size(width: decorationSize, height: decorationSize)
                )
                .offset(x: -decorationSize)
        )
        .union(
            Rectangle().size(width: decorationSize, height: decorationSize)
                .subtracting(
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: config.innerRadius), style: .continuous)
                        .size(width: decorationSize, height: decorationSize)
                )
                .offset(x: config.width + extraWidth)
        )
        .size(width: config.width + extraWidth, height: baseHeight + config.height + 1)
        .offset(y: 1)
}
