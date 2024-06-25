//
//  notchShapeView.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    @ViewBuilder func shapeView(shadow: Bool? = nil, transparentHandle: Bool? = nil) -> some View {
        GeometryReader { geo in
            ShadowedNotchShapeView(shadow: shadow ?? (mode != .closed || hovering), transparentHandle: transparentHandle ?? generalSettings.transparentHandle, fineTuning: fineTuningNotchWidth)
                .frame(width: geo.size.width * (1 - scaleDown), height: geo.size.height * (1 - scaleDown), alignment: .top)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }
    }
}
