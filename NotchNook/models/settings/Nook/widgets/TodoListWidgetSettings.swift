//
//  TodoListWidgetSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

struct TodoListWidgetSettings: WidgetPrefs {
    var size: NookGrid.Size = .init(width: 4, height: 2)
    var showCompleted: Bool = true
    var autoArchiveCompletedAfterDays: Int = 7
}
