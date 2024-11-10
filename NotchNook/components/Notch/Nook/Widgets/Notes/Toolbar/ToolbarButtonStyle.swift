//
//  ToolbarButtonStyle.swift
//  NotchNook
//
//  Created by Lori Montenegro on 10/10/24.
//

import SwiftUI

struct ToolbarButtonStyle: ButtonStyle {
    
    var hovering: Bool
    var active: Bool
    var styleKind: ToolbarButtonStyleKind
    
    func makeBody(configuration: Configuration) -> some View {
        let config = RichToolbarButtonConfiguration.configuration(for: styleKind)
        
        configuration.label
            .foregroundStyle(active ? config.foregroundColor : .secondary)
            .font(config.font)
            .frame(width: config.size, height: config.size)
            .background(config.backgroundColor(hovering, active))
            .background {
                if let bgMaterial = config.backgroundMaterial {
                    Rectangle().fill(bgMaterial)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: config.cornerRadius, style: .continuous))
            .contentShape(config.contentShape)
            .animation(.easeInOut(duration: 0.1), value: hovering)
    }
}
