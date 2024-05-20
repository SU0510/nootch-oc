//
//  NotchShapeView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct ShadowedNotchShapeView: View {
    var minHeight: CGFloat
    var shadow: Bool
    
    var body: some View {
        NotchShape(minHeight: minHeight)
            .fill(.black.shadow(.drop(
                color: .black.opacity(shadow ? 0.75 : 0),
                radius: shadow ? 20 : 0,
                x: 0,
                y: shadow ? 8 : 0
            )))
//            .frame(width: NotchShape.defaultNotchWidth + config.width, height: baseHeight + config.height + 1)
    }
}
