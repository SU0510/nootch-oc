//
//  NotchShapeView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI

struct NotchShapeView: View {
    var extraWidth: CGFloat
    var baseHeight: CGFloat
    var config: NotchShapeConfig
    
    var body: some View {
        notchShape(extraWidth: extraWidth, baseHeight: baseHeight, config: config)
            .fill(.black.shadow(.drop(
                color: .black.opacity(config.shadow ? 0.75 : 0),
                radius: config.shadow ? 20 : 0,
                x: 0,
                y: config.shadow ? 8 : 0
            )))
            .frame(width: config.width + extraWidth, height: baseHeight + config.height + 1)
    }
}
