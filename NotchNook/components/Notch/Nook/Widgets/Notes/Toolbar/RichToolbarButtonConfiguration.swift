//
//  RichToolbarButtonConfiguration.swift
//  NotchNook
//
//  Created by Lori Montenegro on 10/10/24.
//

import SwiftUI

struct RichToolbarButtonConfiguration {
    let foregroundColor: Color
    let font: Font
    let size: CGFloat
    let backgroundColor: (Bool, Bool) -> Color
    let backgroundMaterial: Material?
    let cornerRadius: CGFloat
    let contentShape: AnyShape
}

extension RichToolbarButtonConfiguration {
    static func configuration(for style: ToolbarButtonStyleKind) -> RichToolbarButtonConfiguration {
        switch style {
            case .widget:
                return .init(
                    foregroundColor: .lightYellow,
                    font: .system(size: 15, weight: .semibold),
                    size: 24,
                    backgroundColor: { hovering, active in
                        Color.nonShockingWhite.opacity(hovering ? (active ? 0.15 : 0.075) : 0)
                    },
                    backgroundMaterial: .ultraThinMaterial,
                    cornerRadius: 9,
                    contentShape: AnyShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                )
            case .expanded:
                return .init(
                    foregroundColor: .primary,
                    font: .system(size: 18, weight: .regular),
                    size: 28,
                    backgroundColor: { hovering, active in
                        active ? .yellow.opacity(0.2) : (hovering ? .gray.opacity(0.1) : .clear)
                    },
                    backgroundMaterial: nil,
                    cornerRadius: 6,
                    contentShape: AnyShape(Rectangle())
                )
        }
    }
}
