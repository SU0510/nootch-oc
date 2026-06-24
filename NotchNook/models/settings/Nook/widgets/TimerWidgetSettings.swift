//
//  TimerWidgetSettings.swift
//  NotchNook
//
//  Created by Wren on 25/05/26.
//

import SwiftUI

struct TimerWidgetSettings: WidgetPrefs {
    var size: NookGrid.Size = .init(width: 4, height: 3)
    var showSeconds: Bool = true
    var playSound: Bool = true
}
