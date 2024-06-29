//
//  notchShapeView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView.ShapeModifier {
    @ViewBuilder func notchShapeView(shadow: Bool? = nil, transparentHandle: Bool? = nil) -> some View {
        GeometryReader { geo in
            ShadowedNotchShapeView(
                shadow: shadow ?? (notchNook.mode != .closed || state.hovering),
                transparentHandle: transparentHandle ?? generalSettings.transparentHandle,
                fineTuning: state.fineTuningNotchWidth
            )
            .frame(width: geo.size.width * (1 - state.scaleDown), height: geo.size.height * (1 - state.scaleDown), alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                .animation(.linear(duration: 0.001).delay(shouldRender ? 0 : 0.6)) { $0.opacity(shouldRender ? 1 : 0) }
        }
    }
}
