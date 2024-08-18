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
        let quickPeeksNotEmpty = !(notchNook.quickPeeks?.isEmpty ?? true)
        GeometryReader { geo in
            ShadowedNotchShapeView(
                shadow: shadow ?? (quickPeeksNotEmpty || notchNook.mode != .closed || state.hovering || notchNook.indicator != nil || (intro && state.showIntro)),
                transparentHandle: transparentHandle ?? generalSettings.transparentHandle,
                fineTuning: state.fineTuningNotchWidth
            )
            .frame(width: geo.size.width * (1 - state.scaleDown), height: max(notchSize.height + 1, geo.size.height * (1 - state.scaleDown * 6)), alignment: .top)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .animation(.linear(duration: 0.001).delay(shouldRender ? 0 : 0.6)) { $0.opacity(shouldRender ? 1 : 0) }
        }
    }
}
