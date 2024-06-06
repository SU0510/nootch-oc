//
//  WidgetsSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct NookSettings: Preferences {
    var size = NookGrid.Size(width: 11, height: 2)
    var enabledWidgets: [NookWidget] = [.media, .shortcuts, .mirror]
    var showDividers = true
    var widgetsPadding: Double = 12
}
