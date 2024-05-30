//
//  ShortcutsWidgetSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 27/05/24.
//

import SwiftUI

struct ShortcutsWidgetSettings: WidgetPrefs {
    var size: Grid.Size = .init(width: 4, height: 2)
    var shortcutsToDisplay = [String]()
    var shortcutButtonWidth = Grid.Point(4)
}
