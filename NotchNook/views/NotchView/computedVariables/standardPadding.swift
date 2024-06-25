//
//  standardPadding.swift
//  NotchNook
//
//  Created by Igor Marcossi on 24/06/24.
//

import Foundation
import SwiftUI

extension NotchView {
    var standardPadding: EdgeInsets {
        var pad: Double = 0
        if mode == .closed {
            if hovering {
                if pressing {
                    pad = 4
                } else {
                    pad = 8
                }
            } else {
                pad = 0
            }
        } else {
            pad = generalSettings.contentPadding
        }
        return EdgeInsets(top: 0, leading: pad, bottom: pad, trailing: pad)
    }
}
