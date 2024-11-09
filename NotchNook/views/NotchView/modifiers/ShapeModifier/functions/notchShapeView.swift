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
        let isFineTuningHeight = state.notchState == .fineTuningHeight
        
        GeometryReader { geo in
            let scaledHeight = geo.size.height * (1 - state.scaleDown * 6)
            let shouldBeShadowed = quickPeeksNotEmpty || notchNook.mode != .closed || state.hovering || notchNook.indicator != nil || (intro && state.showIntro)

            ShadowedNotchShapeView(
                isShadowed: shadow ?? shouldBeShadowed,
                transparentHandle: transparentHandle ?? generalSettings.transparentHandle,
                fineTuning: state.notchState == .fineTuningWidth || state.notchState == .fineTuningHeight
            )
            .frame(
                width: isFineTuningHeight ? geo.size.width : geo.size.width * (1 - state.scaleDown),
                height: isFineTuningHeight ? min(notchSize.height + 1, scaledHeight) : max(notchSize.height + 1, scaledHeight),
                alignment: .top
            )
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .animation(.linear(duration: 0.001).delay(shouldRender ? 0 : 0.6)) { $0.opacity(shouldRender ? 1 : 0) }
            .offset(x: isFineTuningHeight ? -20 : 0)
        }
    }
}
