//
//  NotchViewComputedVars.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    var actualScaleX: Double {
        let padFactor = notchNook.mode != .closed || state.animatingBack ? 0 : (state.panPadding.bottom * 0.02)
        let sd = (state.scaleDown + padFactor) * (padFactor > 0 ? -1 : 1)
        return (state.hovering && !state.pressing && notchNook.mode == .closed && !state.animatingBack ? NotchView.hoverScale : 1) - sd
    }
    var actualScaleY: Double {
        let padFactor = notchNook.mode != .closed || state.animatingBack ? 0 : (state.panPadding.bottom * 0.0075)
        let sd = ((state.scaleDown + padFactor) * (notchNook.mode == .closed ? 3 : 6)) * (padFactor > 0 ? -1 : 1)
        return (state.hovering && !state.pressing && notchNook.mode == .closed && !state.animatingBack ? NotchView.hoverScale : 1) - sd
    }
    
    var standardPadding: EdgeInsets {
        var pad: Double = 0
        if notchNook.mode == .closed {
            if state.hovering {
                if state.pressing {
                    pad = NotchView.paddingWhileHovering / 2
                } else {
                    pad = NotchView.paddingWhileHovering
                }
            } else {
                pad = 0
            }
        } else {
            pad = generalSettings.contentPadding
        }
        return EdgeInsets(top: 1, leading: pad, bottom: pad, trailing: pad)
    }
}
