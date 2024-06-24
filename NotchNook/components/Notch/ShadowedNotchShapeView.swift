//
//  NotchShapeView.swift
//  Notchway
//
//  Created by Igor Marcossi on 12/05/24.
//

import SwiftUI
import Defaults

struct ShadowedNotchShapeView: View, Equatable {
    static func == (lhs: ShadowedNotchShapeView, rhs: ShadowedNotchShapeView) -> Bool {
        lhs.shadow == rhs.shadow && lhs.transparentHandle == rhs.transparentHandle
    }
    
    var shadow: Bool
    var transparentHandle: Bool
    @Environment(\.notchSize) private var notchSize
    @Default(.generalSettings) private var generalSettings
    var body: some View {
        let notchSize = notchSize.height == 0 ? generalSettings.handleSize : notchSize
        if !generalSettings.transluscent {
            NotchShape(notchSize: notchSize)
                .fill(.black.opacity(transparentHandle && !shadow && notchSize.height == 0 ? 0 : 1).shadow(.drop(
                    color: .black.opacity(shadow ? 0.75 : 0),
                    radius: shadow ? 20 : 0,
                    x: 0,
                    y: shadow ? 8 : 0
                )))
        } else {
            VisualEffectViews()
                .padding(.horizontal, -24)
                .clipShape(NotchShape(notchSize: notchSize))
                .shadow(color: .black.opacity(shadow ? 0.75 : 0), radius: shadow ? 20 : 0, y: shadow ? 8 : 0)
        }
    }
}
