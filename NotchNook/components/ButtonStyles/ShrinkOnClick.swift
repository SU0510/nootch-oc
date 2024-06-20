//
//  ShrinkOnClick.swift
//  NotchNook
//
//  Created by Igor Marcossi on 20/05/24.
//

import SwiftUI

struct ShrinkOnClick: ButtonStyle {
    static let animation: Animation = .smooth(duration: 0.35, extraBounce: 0.5)
    var minSize: CGFloat = 0.85
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .animation(Self.animation) { v in
                v.scaleEffect(configuration.isPressed ? minSize : 1)
            }
    }
}
