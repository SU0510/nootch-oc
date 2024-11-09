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
        let padFactor = notchNook.mode != .closed || viewModel.animatingBack ? 0 : (viewModel.panPadding.bottom * 0.02)
        let sd = (viewModel.scaleDown + padFactor) * (padFactor > 0 ? -1 : 1)
        let quickPeeksNotEmpty = !(notchNook.quickPeeks?.isEmpty ?? true)
        return ((quickPeeksNotEmpty || viewModel.hovering) && !viewModel.pressing && notchNook.mode == .closed && !viewModel.animatingBack ? NotchView.hoverScale : 1) - sd
    }
    var actualScaleY: Double {
        let padFactor = notchNook.mode != .closed || viewModel.animatingBack ? 0 : (viewModel.panPadding.bottom * 0.0075)
        let sd = ((viewModel.scaleDown + padFactor) * (notchNook.mode == .closed ? 3 : 6)) * (padFactor > 0 ? -1 : 1)
        let quickPeeksNotEmpty = !(notchNook.quickPeeks?.isEmpty ?? true)
        return ((quickPeeksNotEmpty || viewModel.hovering) && !viewModel.pressing && notchNook.mode == .closed && !viewModel.animatingBack ? NotchView.hoverScale : 1) - sd
    }
    
    var standardPadding: EdgeInsets {
        var pad: Double = 0
        if notchNook.mode == .closed {
            if (viewModel.hovering || !(notchNook.quickPeeks?.isEmpty ?? true)) && notchNook.indicator == nil {
                if viewModel.pressing {
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
