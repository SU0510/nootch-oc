//
//  NotesWidgetSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 25/06/24.
//

import SwiftUI

struct NotesWidgetSettings: WidgetPrefs {
    var size: NookGrid.Size = .init(width: 5, height: 2)
    var showScrollIndicator = false
}
