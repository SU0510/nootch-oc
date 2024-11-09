//
//  NotchShapeView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import Defaults
import SmoothGradient

struct ShadowedNotchShapeView: View, Equatable {
    static func == (lhs: ShadowedNotchShapeView, rhs: ShadowedNotchShapeView) -> Bool {
        lhs.isShadowed == rhs.isShadowed && 
        lhs.transparentHandle == rhs.transparentHandle &&
        lhs.fineTuning == rhs.fineTuning
    }
    
    var isShadowed: Bool
    var transparentHandle: Bool
    var fineTuning: Bool = false
    
    @Environment(\.notchSize) private var notchSize
    @Environment(\.generalSettings) private var generalSettings

    var body: some View {
        let notchSize = notchSize.height == 0 ? generalSettings.handleSize : notchSize
        let color: Color = fineTuning ? .purple : .black.opacity(transparentHandle && !isShadowed && notchSize.height == 0 ? 0 : 1)
        if !generalSettings.transluscent {
            NotchShape(notchSize: notchSize)
                .fill(
                    color.shadow(
                        .drop(
                            color: .black.opacity(isShadowed ? 0.75 : 0),
                            radius: isShadowed ? 20 : 0,
                            x: 0,
                            y: isShadowed ? 8 : 0
                        )
                    )
                )
        } else {
            VisualEffectViews()
                .padding(.horizontal, -24)
                .clipShape(NotchShape(notchSize: notchSize))
                .shadow(color: .black.opacity(isShadowed ? 0.75 : 0), radius: isShadowed ? 20 : 0, y: isShadowed ? 8 : 0)
        }
    }
}
