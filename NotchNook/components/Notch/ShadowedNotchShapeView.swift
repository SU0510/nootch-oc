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
    @Environment(\.notchHeight) private var notchHeight
    @Default(.generalSettings) private var generalSettings
    var body: some View {
        if !generalSettings.transluscent {
            NotchShape(notchHeight: notchHeight.isZero ? generalSettings.handleSize.height : notchHeight)
                .fill(.black.opacity(transparentHandle && !shadow && notchHeight == 0 ? 0 : 1).shadow(.drop(
                    color: .black.opacity(shadow ? 0.75 : 0),
                    radius: shadow ? 20 : 0,
                    x: 0,
                    y: shadow ? 8 : 0
                )))
        } else {
            VisualEffectViews()
                .padding(.horizontal, -24)
                .clipShape(NotchShape(notchHeight: notchHeight.isZero ? generalSettings.handleSize.height : notchHeight))
                .shadow(color: .black.opacity(shadow ? 0.75 : 0), radius: shadow ? 20 : 0, y: shadow ? 8 : 0)
        }
    }
}
