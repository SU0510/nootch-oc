//
//  ShortcutsWidgetSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct ShortcutsWidgetSettings: WidgetPrefs {
    var size: NookGrid.Size = .init(width: 4, height: 2)
    var shortcutsToDisplay = [String]()
    var shortcutButtonWidth = NookGrid.Point(4)
}
