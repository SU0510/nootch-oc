//
//  CalendarWidgetSettings.swift
//  NotchNook
//
//  Created by Igor Marcossi on 04/06/24.
//

import SwiftUI

struct CalendarWidgetSettings: WidgetPrefs {
    var size: NookGrid.Size = .init(width: 5, height: 2)
    var shouldShowTodayPastEvents: Bool = false
    var shouldShowAllDayEvents: Bool = false
    var numberOfDaysBehindToDisplay: Int = 7
    var numberOfDaysAheadToDisplay: Int = 7
    var selectedCalendars: [String]? = nil
}

 
